from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = (
            'notification_id', 'notification_type',
            'title', 'body', 'related_request_id', 'related_conversation_id',
            'is_read', 'created_at',
        )
        read_only_fields = fields
