from .models import Notification


def notify_user(user, notification_type: str, title: str, body: str,
                related_request_id=None, related_conversation_id=None):
    """Send a notification to a Service User."""
    Notification.objects.create(
        recipient_user=user,
        notification_type=notification_type,
        title=title,
        body=body,
        related_request_id=related_request_id,
        related_conversation_id=related_conversation_id,
    )


def notify_provider(provider, notification_type: str, title: str, body: str,
                    related_request_id=None, related_conversation_id=None):
    """Send a notification to a Service Provider."""
    Notification.objects.create(
        recipient_provider=provider,
        notification_type=notification_type,
        title=title,
        body=body,
        related_request_id=related_request_id,
        related_conversation_id=related_conversation_id,
    )
