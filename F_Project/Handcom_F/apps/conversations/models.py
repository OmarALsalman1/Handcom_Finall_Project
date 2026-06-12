import os
from django.db import models
from django.core.exceptions import ValidationError
from apps.accounts.models import User, ServiceProvider
from apps.services.models import ServiceRequest


def _validate_file_size(value):
    if value.size > 5 * 1024 * 1024:
        raise ValidationError('Attachment size cannot exceed 5 MB.')


def _validate_attachment_ext(value):
    allowed = {'.jpg', '.jpeg', '.png', '.gif', '.mp3', '.wav', '.ogg', '.pdf'}
    ext = os.path.splitext(value.name)[1].lower()
    if ext not in allowed:
        raise ValidationError('Attachment type not supported. Allowed: image, audio, PDF.')


class Conversation(models.Model):
    STATUS = [('open', 'Open'), ('closed', 'Closed')]
    conversation_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='conversations')
    service_provider = models.ForeignKey(
        ServiceProvider, on_delete=models.CASCADE, related_name='conversations'
    )
    service_request = models.ForeignKey(
        ServiceRequest, on_delete=models.SET_NULL, related_name='conversations',
        null=True, blank=True,
    )
    conversation_status = models.CharField(max_length=10, choices=STATUS, default='open')
    started_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'conversation'
        ordering = ['-started_at']
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'service_provider'],
                name='unique_conversation_per_user_provider',
            ),
        ]

    def __str__(self):
        return f"Conversation #{self.conversation_id} ({self.conversation_status})"


class Message(models.Model):
    SENDER = [('user', 'User'), ('service_provider', 'Service Provider')]
    message_id = models.AutoField(primary_key=True)
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name='messages')
    sender_type = models.CharField(max_length=16, choices=SENDER)
    content = models.TextField()
    attachment = models.FileField(
        upload_to='messages/%Y/%m/', blank=True, null=True,
        validators=[_validate_file_size, _validate_attachment_ext],
    )
    sent_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'message'
        ordering = ['sent_at']

    def __str__(self):
        return f"[{self.sender_type}] {self.content[:50]}"
