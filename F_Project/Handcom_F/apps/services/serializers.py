from rest_framework import serializers
from apps.accounts.serializers import ServiceProviderProfileSerializer
from .models import ServiceRequest, Service, ServiceRequestStatusTracking, SavedProvider


class ServiceRequestCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceRequest
        fields = (
            'service_type', 'location', 'description',
            'image', 'voice_note', 'scheduled_for',
        )


class ServiceRequestSerializer(serializers.ModelSerializer):
    current_status = serializers.CharField(read_only=True)
    service_provider = ServiceProviderProfileSerializer(read_only=True)
    user_name = serializers.SerializerMethodField()
    service_id = serializers.SerializerMethodField()

    class Meta:
        model = ServiceRequest
        fields = (
            'service_request_id', 'user', 'user_name', 'service_provider',
            'service_type', 'location', 'description',
            'image', 'voice_note', 'scheduled_for',
            'current_status', 'created_at', 'service_id',
        )
        read_only_fields = fields

    def get_user_name(self, obj):
        return obj.user.full_name if obj.user else ''

    def get_service_id(self, obj):
        try:
            return obj.service.service_id
        except Exception:
            return None


class ServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = (
            'service_id', 'service_request', 'service_provider',
            'service_name', 'service_description', 'service_date',
        )


class ServiceCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = ('service_request', 'service_name', 'service_description', 'service_date')

    def validate_service_request(self, req):
        if req.current_status != 'completed':
            raise serializers.ValidationError(
                'A Service record can only be created for a completed request.'
            )
        if hasattr(req, 'service'):
            raise serializers.ValidationError(
                'A Service record already exists for this request.'
            )
        return req


class ServiceRequestStatusTrackingSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceRequestStatusTracking
        fields = ('tracking_id', 'status', 'status_date')


class SavedProviderSerializer(serializers.ModelSerializer):
    service_provider = ServiceProviderProfileSerializer(read_only=True)

    class Meta:
        model = SavedProvider
        fields = ('saved_id', 'service_provider', 'saved_at')
