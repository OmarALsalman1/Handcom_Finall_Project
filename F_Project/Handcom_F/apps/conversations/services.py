from rest_framework.exceptions import ValidationError


class RealtimeProvider:
    """
    No-op stub. Replace with Stream Chat / Django Channels in a later sprint.
    Interface contract: publish(conversation_id, message) -> None
    """

    def publish(self, conversation_id: int, message) -> None:
        pass


_realtime_provider = RealtimeProvider()


class ConversationService:

    def send_message(self, conversation, sender_type, content, attachment=None):
        from .models import Message

        if conversation.conversation_status == 'closed':
            raise ValidationError('Cannot send messages on a closed conversation.')

        message = Message.objects.create(
            conversation=conversation,
            sender_type=sender_type,
            content=content,
            attachment=attachment,
        )
        _realtime_provider.publish(conversation.conversation_id, message)
        return message
