from rest_framework import serializers
from .models import AIConversation, AIMessage


class AIMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = AIMessage
        fields = ('ai_message_id', 'sender', 'input_type', 'content', 'media_url', 'sent_at')
        read_only_fields = fields


class AIConversationSerializer(serializers.ModelSerializer):
    messages = AIMessageSerializer(many=True, read_only=True)

    class Meta:
        model = AIConversation
        fields = ('ai_conversation_id', 'started_at', 'last_analysis', 'messages')
        read_only_fields = fields


class AIConversationListSerializer(serializers.ModelSerializer):
    class Meta:
        model = AIConversation
        fields = ('ai_conversation_id', 'started_at', 'last_analysis')
        read_only_fields = fields


class AIChatInputSerializer(serializers.Serializer):
    text = serializers.CharField(required=False, allow_blank=True, default='')
    image = serializers.ImageField(required=False, allow_null=True)
    voice = serializers.FileField(required=False, allow_null=True)
    conversation_id = serializers.IntegerField(required=False, allow_null=True)
    lat = serializers.FloatField(required=False, allow_null=True)
    lng = serializers.FloatField(required=False, allow_null=True)
    lang = serializers.ChoiceField(choices=['ar', 'en'], default='ar', required=False)

    def validate(self, data):
        if not data.get('text') and not data.get('image') and not data.get('voice'):
            raise serializers.ValidationError(
                'At least one of text, image, or voice must be provided.'
            )
        return data


class AICreateRequestSerializer(serializers.Serializer):
    ai_conversation_id = serializers.IntegerField()
    location = serializers.CharField(max_length=255)
    service_provider_id = serializers.IntegerField(required=False, allow_null=True)
