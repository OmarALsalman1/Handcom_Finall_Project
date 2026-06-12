from rest_framework import serializers
from .models import ServiceProviderSchedule


class ScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceProviderSchedule
        fields = (
            'service_provider_schedule_id', 'service_provider',
            'working_date', 'start_time', 'end_time',
        )
        read_only_fields = ('service_provider_schedule_id', 'service_provider')


class ScheduleWriteSerializer(serializers.Serializer):
    working_date = serializers.DateField()
    start_time = serializers.TimeField()
    end_time = serializers.TimeField()
