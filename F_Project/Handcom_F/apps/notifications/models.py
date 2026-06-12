from django.db import models
from apps.accounts.models import User, ServiceProvider


class Notification(models.Model):
    TYPES = [
        ('new_request',       'New Request'),
        ('request_accepted',  'Request Accepted'),
        ('request_completed', 'Request Completed'),
        ('request_cancelled', 'Request Cancelled'),
        ('new_message',       'New Message'),
        ('new_rating',        'New Rating'),
    ]

    notification_id    = models.AutoField(primary_key=True)
    recipient_user     = models.ForeignKey(
        User, null=True, blank=True,
        on_delete=models.CASCADE, related_name='notifications',
    )
    recipient_provider = models.ForeignKey(
        ServiceProvider, null=True, blank=True,
        on_delete=models.CASCADE, related_name='notifications',
    )
    notification_type  = models.CharField(max_length=30, choices=TYPES)
    title              = models.CharField(max_length=200)
    body               = models.TextField()
    related_request_id      = models.IntegerField(null=True, blank=True)
    related_conversation_id = models.IntegerField(null=True, blank=True)
    is_read            = models.BooleanField(default=False)
    created_at         = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notification'
        ordering = ['-created_at']

    def __str__(self):
        return f'[{self.notification_type}] {self.title}'

