import math
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from drf_spectacular.utils import extend_schema

from .models import User, ServiceProvider
from .serializers import (
    UserRegistrationSerializer,
    ServiceProviderRegistrationSerializer,
    UserTokenObtainPairSerializer,
    ServiceProviderLoginSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer,
    UserProfileSerializer,
    ServiceProviderProfileSerializer,
)
from .services import OTPService
from .permissions import IsServiceUser, IsServiceProvider

_otp_service = OTPService()


# ── Service User Auth ─────────────────────────────────────────────────────────

@extend_schema(tags=['Auth'])
class UserRegisterView(generics.CreateAPIView):
    permission_classes = [AllowAny]
    serializer_class = UserRegistrationSerializer

    def create(self, request, *args, **kwargs):
        email = request.data.get('email', '').strip()
        unverified = User.objects.filter(email__iexact=email, is_email_verified=False).first()
        if unverified:
            _otp_service.send(unverified.email, 'service_user', purpose='verification')
            return Response(
                {
                    'detail': 'هذا البريد الإلكتروني مسجّل ولم يُفعَّل بعد. تم إعادة إرسال رمز التحقق.',
                    'email': unverified.email,
                },
                status=status.HTTP_200_OK,
            )

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        _otp_service.send(user.email, 'service_user', purpose='verification')
        return Response(
            {
                'detail': 'تم إنشاء حسابك! تحقق من بريدك الإلكتروني للحصول على رمز التحقق.',
                'email': user.email,
            },
            status=status.HTTP_201_CREATED,
        )


@extend_schema(tags=['Auth'])
class UserLoginView(TokenObtainPairView):
    permission_classes = [AllowAny]
    serializer_class = UserTokenObtainPairSerializer


# ── Service Provider Auth ─────────────────────────────────────────────────────

@extend_schema(tags=['Auth'])
class ServiceProviderRegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        unverified = ServiceProvider.objects.filter(email__iexact=email, is_email_verified=False).first()
        if unverified:
            _otp_service.send(unverified.email, 'service_provider', purpose='verification')
            return Response(
                {
                    'detail': 'هذا البريد الإلكتروني مسجّل ولم يُفعَّل بعد. تم إعادة إرسال رمز التحقق.',
                    'email': unverified.email,
                },
                status=status.HTTP_200_OK,
            )

        serializer = ServiceProviderRegistrationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        provider = serializer.save()
        _otp_service.send(provider.email, 'service_provider', purpose='verification')
        return Response(
            {
                'detail': 'تم إنشاء حسابك! تحقق من بريدك الإلكتروني للحصول على رمز التحقق.',
                'email': provider.email,
            },
            status=status.HTTP_201_CREATED,
        )


@extend_schema(tags=['Auth'])
class ServiceProviderLoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = ServiceProviderLoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data, status=status.HTTP_200_OK)


# ── Email Verification ────────────────────────────────────────────────────────

@extend_schema(tags=['Auth'])
class VerifyEmailView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        otp = request.data.get('otp', '').strip()
        role = request.data.get('role', '').strip()

        if not email or not otp or not role:
            return Response(
                {'detail': 'email و otp و role مطلوبة.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not _otp_service.verify(email, role, otp):
            return Response(
                {'detail': 'رمز التحقق غير صحيح أو منتهي الصلاحية.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if role == 'service_user':
            updated = User.objects.filter(email=email).update(is_email_verified=True)
        else:
            updated = ServiceProvider.objects.filter(email=email).update(is_email_verified=True)

        if not updated:
            return Response(
                {'detail': 'الحساب غير موجود.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response({'detail': 'تم تفعيل بريدك الإلكتروني بنجاح! يمكنك الآن تسجيل الدخول.'})


@extend_schema(tags=['Auth'])
class ResendVerificationOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        role = request.data.get('role', '').strip()

        if not email or not role:
            return Response(
                {'detail': 'email و role مطلوبان.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        exists = False
        if role == 'service_user':
            exists = User.objects.filter(email=email, is_email_verified=False).exists()
        else:
            exists = ServiceProvider.objects.filter(email=email, is_email_verified=False).exists()

        if not exists:
            return Response(
                {'detail': 'الحساب غير موجود أو البريد الإلكتروني مفعّل مسبقاً.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        _otp_service.send(email, role, purpose='verification')
        return Response({'detail': 'تم إعادة إرسال رمز التحقق.'})


# ── Password Reset ────────────────────────────────────────────────────────────

@extend_schema(tags=['Auth'])
class PasswordResetRequestView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']
        role = serializer.validated_data.get('role')

        if not role:
            if User.objects.filter(email=email).exists():
                role = 'service_user'
            elif ServiceProvider.objects.filter(email=email).exists():
                role = 'service_provider'

        if role:
            _otp_service.send(email, role, purpose='reset')

        return Response({'detail': 'إذا كان البريد موجوداً، سيصلك رمز التحقق.'})


@extend_schema(tags=['Auth'])
class PasswordResetConfirmView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']
        role = serializer.validated_data.get('role')
        otp = serializer.validated_data['otp']
        new_password = serializer.validated_data['new_password']

        if not role:
            if User.objects.filter(email=email).exists():
                role = 'service_user'
            elif ServiceProvider.objects.filter(email=email).exists():
                role = 'service_provider'

        if not role or not _otp_service.verify(email, role, otp):
            return Response(
                {'detail': 'رمز التحقق غير صحيح أو منتهي الصلاحية.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if role == 'service_user':
            try:
                user = User.objects.get(email=email)
                user.set_password(new_password)
                user.save(update_fields=['password'])
            except User.DoesNotExist:
                return Response({'detail': 'الحساب غير موجود.'}, status=status.HTTP_404_NOT_FOUND)
        else:
            try:
                provider = ServiceProvider.objects.get(email=email)
                provider.set_password(new_password)
                provider.save(update_fields=['password'])
            except ServiceProvider.DoesNotExist:
                return Response({'detail': 'الحساب غير موجود.'}, status=status.HTTP_404_NOT_FOUND)

        return Response({'detail': 'تم تغيير كلمة المرور بنجاح.'})


# ── Service User Profile ──────────────────────────────────────────────────────

@extend_schema(tags=['Service Users'])
class UserMeView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated, IsServiceUser]
    serializer_class = UserProfileSerializer
    http_method_names = ['get', 'put', 'patch', 'head', 'options']

    def get_object(self):
        return self.request.user


# ── Service Provider Endpoints ────────────────────────────────────────────────

def _haversine_km(lat1, lon1, lat2, lon2):
    """Great-circle distance in km between two (lat, lon) points."""
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2
         + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2))
         * math.sin(dlon / 2) ** 2)
    return R * 2 * math.asin(math.sqrt(a))


_AVAILABILITY_RANK = {'available': 0, 'busy': 1, 'offline': 2}


@extend_schema(tags=['Service Providers'])
class ServiceProviderListView(generics.ListAPIView):
    permission_classes = [AllowAny]
    serializer_class = ServiceProviderProfileSerializer

    def get_queryset(self):
        qs = ServiceProvider.objects.filter(is_email_verified=True)
        availability = self.request.query_params.get('availability_status')
        category = self.request.query_params.get('category')
        if availability:
            qs = qs.filter(availability_status=availability)
        if category:
            qs = qs.filter(service_categories__icontains=f'"{category}"')
        return qs

    def list(self, request, *args, **kwargs):
        qs = self.get_queryset()
        providers = list(qs)

        # Parse optional user coordinates
        try:
            user_lat = float(request.query_params['lat'])
            user_lng = float(request.query_params['lng'])
            has_location = True
        except (KeyError, ValueError):
            has_location = False

        def sort_key(p):
            # 1) distance — providers without coords go to the end
            if has_location and p.latitude is not None and p.longitude is not None:
                dist = _haversine_km(user_lat, user_lng, p.latitude, p.longitude)
            else:
                dist = float('inf')

            # 2) availability (available=0, busy=1, offline=2)
            avail = _AVAILABILITY_RANK.get(p.availability_status, 99)

            # 3) rating (higher is better → negate)
            ratings = p.received_ratings.all()
            avg = (sum(r.rating_value for r in ratings) / len(ratings)
                   if ratings else 0.0)

            return (dist, avail, -avg)

        providers.sort(key=sort_key)

        serializer = self.get_serializer(providers, many=True)
        return Response(serializer.data)


@extend_schema(tags=['Service Providers'])
class ServiceProviderDetailView(generics.RetrieveAPIView):
    permission_classes = [AllowAny]
    serializer_class = ServiceProviderProfileSerializer
    queryset = ServiceProvider.objects.all()
    lookup_field = 'service_provider_id'
    lookup_url_kwarg = 'pk'


@extend_schema(tags=['Service Providers'])
class ServiceProviderMeView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated, IsServiceProvider]
    serializer_class = ServiceProviderProfileSerializer
    http_method_names = ['get', 'put', 'patch', 'head', 'options']

    def get_object(self):
        return self.request.user.provider


@extend_schema(tags=['Service Providers'])
class ServiceProviderAvailabilityView(APIView):
    permission_classes = [IsAuthenticated, IsServiceProvider]

    def patch(self, request):
        provider = request.user.provider
        new_status = request.data.get('availability_status')
        valid = ['available', 'offline']
        if new_status not in valid:
            return Response(
                {'detail': f"availability_status must be one of: {', '.join(valid)}."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        provider.availability_status = new_status
        provider.save(update_fields=['availability_status'])
        return Response({'availability_status': provider.availability_status})
