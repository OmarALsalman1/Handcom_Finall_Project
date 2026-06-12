from django.utils import timezone
from rest_framework.exceptions import ValidationError

from .models import ServiceProviderSchedule


class ScheduleService:
    """All scheduling business rules live here, not in views or serializers."""

    def validate_slot(self, provider, working_date, start_time, end_time, exclude_id=None):
        # Rule 1 — no past dates
        if working_date < timezone.now().date():
            raise ValidationError('Cannot create schedule slots for a past date.')

        # Rule 2 — end_time must be strictly after start_time
        if end_time <= start_time:
            raise ValidationError('end_time must be after start_time.')

        # Rule 3 — no overlap: [new_start, new_end) overlaps [s, e) if new_start < e AND new_end > s
        qs = ServiceProviderSchedule.objects.filter(
            service_provider=provider,
            working_date=working_date,
            start_time__lt=end_time,
            end_time__gt=start_time,
        )
        if exclude_id is not None:
            qs = qs.exclude(pk=exclude_id)
        if qs.exists():
            conflict = qs.first()
            raise ValidationError(
                f'This slot overlaps with an existing slot '
                f'({conflict.start_time.strftime("%H:%M")}–{conflict.end_time.strftime("%H:%M")}) '
                f'on {working_date}.'
            )

    def create_slot(self, provider, working_date, start_time, end_time):
        self.validate_slot(provider, working_date, start_time, end_time)
        return ServiceProviderSchedule.objects.create(
            service_provider=provider,
            working_date=working_date,
            start_time=start_time,
            end_time=end_time,
        )

    def update_slot(self, slot, working_date, start_time, end_time):
        self.validate_slot(
            slot.service_provider, working_date, start_time, end_time,
            exclude_id=slot.service_provider_schedule_id,
        )
        slot.working_date = working_date
        slot.start_time = start_time
        slot.end_time = end_time
        slot.save()
        return slot
