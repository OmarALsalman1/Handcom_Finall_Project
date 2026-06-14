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
            raise ValidationError('Service not found.', code='service_not_found')

        # Rule 1 — rating gate: request must be completed
        if service.service_request.current_status != 'completed':
            raise ValidationError(
                'You can only rate a completed service.', code='service_not_completed'
            )

        # Rule 3 — ownership: only the original requester can rate
        if service.service_request.user != user:
            raise PermissionDenied(
                'You can only rate services you originally requested.',
                code='not_service_owner',
            )

        # Rule 4 — time window: within 30 days of service_date
        deadline = service.service_date + timedelta(days=RATING_WINDOW_DAYS)
        if timezone.now().date() > deadline:
            raise ValidationError(
                f'Rating window has expired '
                f'({RATING_WINDOW_DAYS} days from the service completion date).',
                code='rating_window_expired',
            )

        # Rule 2 — one rating per service per user
        if Rating.objects.filter(user=user, service=service).exists():
            raise ValidationError('You have already rated this service.', code='already_rated')

        return Rating.objects.create(
            user=user,
            service_provider=service.service_provider,
            service=service,
            service_category=service.service_request.service_type,
            rating_value=rating_value,
            rating_comment=rating_comment or '',
        )


def category_or_overall_rating(provider, category=None, fallback=True):
    """Return (average, total) for a provider's received ratings.

    If `category` is given, only ratings for that category are considered.
    When `fallback` is True and the provider has no ratings for that category,
    falls back to all of the provider's ratings instead of returning empty.
    """
    ratings = list(provider.received_ratings.all())
    if category:
        cat_ratings = [r for r in ratings if r.service_category == category]
        if cat_ratings or not fallback:
            ratings = cat_ratings
    if not ratings:
        return None, 0
    return round(sum(r.rating_value for r in ratings) / len(ratings), 2), len(ratings)
