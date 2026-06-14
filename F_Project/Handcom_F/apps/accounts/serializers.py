from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.exceptions import ValidationError as DjangoValidationError

from .models import User, ServiceProvider
from .validators import validate_password_strength, validate_phone, VALID_SERVICE_CATEGORIES


# ── Helpers ──────────────────────────────────────────────────────────────────

def _check_password(value):
    try:
        validate_password_strength(value)
    except DjangoValidationError as e:
        raise serializers.ValidationError(e.messages)
    return value


def _check_phone(value):
    try:
        validate_phone(value)
    except DjangoValidationError as e:
        raise serializers.ValidationError(e.messages)
    return value


# ── Registration ──────────────────────────────────────────────────────────────

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ('full_name', 'email', 'phone', 'password', 'address')

    def validate_email(self, value):
        existing = User.objects.filter(email=value).first()
        if existing:
            if existing.is_email_verified:
                raise serializers.ValidationError(
                    'A user with this email already exists.', code='email_already_exists'
                )
            existing.delete()
        return value

    def validate_password(self, value):
        return _check_password(value)

    def validate_phone(self, value):
        return _check_phone(value)

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)


class ServiceProviderRegistrationSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=100)
    email = serializers.EmailField()
    phone = serializers.CharField(max_length=20)
    password = serializers.CharField(write_only=True, min_length=8)
    experience_years = serializers.IntegerField(min_value=0, default=0)
    service_categories = serializers.ListField(
        child=serializers.CharField(), min_length=1
    )

    def validate_email(self, value):
        existing = ServiceProvider.objects.filter(email=value).first()
        if existing:
            if existing.is_email_verified:
                raise serializers.ValidationError(
                    'A Service Provider with this email already exists.',
                    code='email_already_exists',
                )
            existing.delete()
        return value

    def validate_password(self, value):
        return _check_password(value)

    def validate_phone(self, value):
        return _check_phone(value)

    def validate_service_categories(self, value):
        invalid = set(value) - VALID_SERVICE_CATEGORIES
        if invalid:
            raise serializers.ValidationError(
                f"Invalid categories: {', '.join(sorted(invalid))}. "
                f"Valid options: {', '.join(sorted(VALID_SERVICE_CATEGORIES))}."
            )
        return list(set(value))

    def create(self, validated_data):
        password = validated_data.pop('password')
        provider = ServiceProvider(**validated_data)
        provider.set_password(password)
        provider.save()
        return provider


# ── Login / JWT ───────────────────────────────────────────────────────────────

class UserTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Adds role='service_user' claim to the standard SimpleJWT token."""

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = 'service_user'
        token['email'] = user.email
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        if not self.user.is_email_verified:
            raise AuthenticationFailed(
                'البريد الإلكتروني غير مفعّل. تحقق من صندوق البريد الوارد.',
                code='email_not_verified',
            )
        return data


class ServiceProviderLoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        try:
            provider = ServiceProvider.objects.get(email=data['email'])
        except ServiceProvider.DoesNotExist:
            raise AuthenticationFailed(
                'No active account found with the given credentials.',
                code='invalid_credentials',
            )
        if not provider.check_password(data['password']):
            raise AuthenticationFailed(
                'No active account found with the given credentials.',
                code='invalid_credentials',
            )
        if not provider.is_email_verified:
            raise AuthenticationFailed(
                'البريد الإلكتروني غير مفعّل. تحقق من صندوق البريد الوارد.',
                code='email_not_verified',
            )

        refresh = RefreshToken()
        refresh['role'] = 'service_provider'
        refresh['email'] = provider.email
        refresh['provider_id'] = provider.service_provider_id

        return {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'role': 'service_provider',
            'email': provider.email,
            'provider_id': provider.service_provider_id,
        }


# ── Password reset ────────────────────────────────────────────────────────────

class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField()
    # role is optional; backend auto-detects which table the email belongs to
    role = serializers.ChoiceField(
        choices=['service_user', 'service_provider'], required=False
    )


class PasswordResetConfirmSerializer(serializers.Serializer):
    email = serializers.EmailField()
    # role is optional; backend auto-detects which table the email belongs to
    role = serializers.ChoiceField(
        choices=['service_user', 'service_provider'], required=False
    )
    otp = serializers.CharField(max_length=6, min_length=6)
    new_password = serializers.CharField(min_length=6, write_only=True)

    def validate_new_password(self, value):
        return _check_password(value)


# ── Profile ───────────────────────────────────────────────────────────────────

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('user_id', 'full_name', 'email', 'phone', 'address', 'created_at')
        read_only_fields = ('user_id', 'email', 'created_at')


class ServiceProviderProfileSerializer(serializers.ModelSerializer):
    average_rating = serializers.SerializerMethodField()
    total_ratings = serializers.SerializerMethodField()

    class Meta:
        model = ServiceProvider
        fields = (
            'service_provider_id', 'full_name', 'email', 'phone',
            'experience_years', 'availability_status', 'service_categories',
            'bio', 'services_offered', 'latitude', 'longitude',
            'created_at', 'average_rating', 'total_ratings',
        )
        read_only_fields = ('service_provider_id', 'email', 'created_at')

    def get_average_rating(self, obj):
        from apps.ratings.services import category_or_overall_rating

        avg, _ = category_or_overall_rating(obj, self.context.get('category'), fallback=False)
        return avg

    def get_total_ratings(self, obj):
        from apps.ratings.services import category_or_overall_rating

        _, total = category_or_overall_rating(obj, self.context.get('category'), fallback=False)
        return total
