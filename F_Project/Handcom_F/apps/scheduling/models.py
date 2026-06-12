from django.db import models
from django.core.exceptions import ValidationError
from apps.accounts.models import ServiceProvider
from apps.ai_assistant.models import AIAssistant


class ServiceProviderSchedule(models.Model):
    service_provider_schedule_id = models.AutoField(primary_key=True)
    service_provider = models.ForeignKey(
        ServiceProvider, on_delete=models.CASCADE, related_name='schedules'
    )
    ai = models.ForeignKey(
        AIAssistant, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='managed_schedules'
    )
    working_date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()

    class Meta:
        db_table = 'service_provider_schedule'
        ordering = ['working_date', 'start_time']

    def __str__(self):
        return f"{self.service_provider} — {self.working_date} {self.start_time}-{self.end_time}"

    def clean(self):
        if self.end_time <= self.start_time:
            raise ValidationError("end_time must be after start_time")
