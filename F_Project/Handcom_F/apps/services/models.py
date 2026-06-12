from django.db import models
from django.core.exceptions import ValidationError
from apps.accounts.models import User, ServiceProvider


def _validate_file_size(value):
    if value.size > 5 * 1024 * 1024:
        raise ValidationError('File size cannot exceed 5 MB.')


class ServiceRequest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('on_hold', 'On Hold'),
        ('accepted', 'Accepted'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    service_request_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='service_requests')
    service_provider = models.ForeignKey(
        ServiceProvider, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='assigned_requests'
    )
    service_type = models.CharField(max_length=100)
    location = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    image = models.ImageField(
        upload_to='requests/%Y/%m/', blank=True, null=True,
        validators=[_validate_file_size]
    )
    voice_note = models.FileField(
        upload_to='voices/%Y/%m/', blank=True, null=True,
        validators=[_validate_file_size]
    )
    scheduled_for = models.DateTimeField(blank=True, null=True)
    current_status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending', db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'service_request'
        ordering = ['-created_at']

    def __str__(self):
        return f"Request #{self.service_request_id} [{self.current_status}] - {self.service_type}"


class Service(models.Model):
    service_id = models.AutoField(primary_key=True)
    service_request = models.OneToOneField(
        ServiceRequest, on_delete=models.CASCADE, related_name='service'
    )
    service_provider = models.ForeignKey(
        ServiceProvider, on_delete=models.PROTECT, related_name='services'
    )
    service_name = models.CharField(max_length=150)
    service_description = models.TextField(blank=True, null=True)
    service_date = models.DateField()

    class Meta:
        db_table = 'service'

    def __str__(self):
        return self.service_name


class ServiceRequestStatusTracking(models.Model):
    STATUS = [
        ('pending', 'Pending'),
        ('on_hold', 'On Hold'),
        ('accepted', 'Accepted'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]
    tracking_id = models.AutoField(primary_key=True)
    service_request = models.ForeignKey(
        ServiceRequest, on_delete=models.CASCADE, related_name='status_history'
    )
    status = models.CharField(max_length=20, choices=STATUS)
    status_date = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'service_request_status_tracking'
        ordering = ['-status_date']

    def __str__(self):
        return f"Request #{self.service_request_id} → {self.status}"


class SavedProvider(models.Model):
    """Allows a Service User to bookmark Service Providers."""
    saved_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_providers')
    service_provider = models.ForeignKey(
        ServiceProvider, on_delete=models.CASCADE, related_name='saved_by'
    )
    saved_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'saved_provider'
        unique_together = ('user', 'service_provider')
        ordering = ['-saved_at']

    def __str__(self):
        return f"{self.user} saved {self.service_provider}"
