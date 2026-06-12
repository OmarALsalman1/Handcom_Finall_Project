from datetime import timedelta

from django.utils import timezone
from rest_framework.exceptions import ValidationError, PermissionDenied

from .models import Rating

RATING_WINDOW_DAYS = 30


class RatingService:

    def submit_rating(self, user, service_id, rating_value, rating_comment=''):
        from apps.services.models import Service

        try:
            service = Service.objects.select_related(
                'service_request__user', 'service_provider'
            ).get(pk=service_id)
        except Service.DoesNotExist:
            raise ValidationError('Service not found.')

        # Rule 1 — rating gate: request must be completed
        if service.service_request.current_status != 'completed':
            raise ValidationError('You can only rate a completed service.')

        # Rule 3 — ownership: only the original requester can rate
        if service.service_request.user != user:
            raise PermissionDenied('You can only rate services you originally requested.')

        # Rule 4 — time window: within 30 days of service_date
        deadline = service.service_date + timedelta(days=RATING_WINDOW_DAYS)
        if timezone.now().date() > deadline:
            raise ValidationError(
                f'Rating window has expired '
                f'({RATING_WINDOW_DAYS} days from the service completion date).'
            )

        # Rule 2 — one rating per service per user
        if Rating.objects.filter(user=user, service=service).exists():
            raise ValidationError('You have already rated this service.')

        return Rating.objects.create(
            user=user,
            service_provider=service.service_provider,
            service=service,
            service_category=service.service_request.service_type,
            rating_value=rating_value,
            rating_comment=rating_comment or '',
        )
