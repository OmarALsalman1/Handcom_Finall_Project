from rest_framework import serializers
from .models import Conversation, Message


class ConversationSerializer(serializers.ModelSerializer):
    user_name = serializers.SerializerMethodField()
    provider_name = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = (
            'conversation_id', 'user', 'service_provider', 'service_request',
            'conversation_status', 'started_at', 'user_name', 'provider_name',
        )
        read_only_fields = fields

    def get_user_name(self, obj):
        return obj.user.full_name if obj.user else ''

    def get_provider_name(self, obj):
        return obj.service_provider.full_name if obj.service_provider else ''


class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ('message_id', 'sender_type', 'content', 'attachment', 'sent_at')
        read_only_fields = fields


class MessageCreateSerializer(serializers.Serializer):
    content = serializers.CharField(max_length=2000)
    attachment = serializers.FileField(required=False, allow_null=True)

    def validate_attachment(self, value):
        if value is None:
            return value
        # Size and extension validators are on the model field;
        # trigger them manually here so we get 400 before DB write.
        from .models import _validate_file_size, _validate_attachment_ext
        from django.core.exceptions import ValidationError as DjangoValidationError
        try:
            _validate_file_size(value)
            _validate_attachment_ext(value)
        except DjangoValidationError as e:
            raise serializers.ValidationError(e.messages)
        return value
