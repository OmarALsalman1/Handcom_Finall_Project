from datetime import timedelta

from django.utils import timezone
from rest_framework.exceptions import ValidationError, PermissionDenied

from .models import ServiceRequest, ServiceRequestStatusTracking, SavedProvider

# A provider can't have two active requests scheduled within this window of each other.
SCHEDULING_CONFLICT_BUFFER = timedelta(hours=2)

# A request directed at a specific provider auto-cancels if left 'pending' this long.
PENDING_REQUEST_EXPIRY = timedelta(hours=1)

# ── State machine ─────────────────────────────────────────────────────────────

VALID_TRANSITIONS = {
    'pending':     {'accepted', 'cancelled'},
    'on_hold':     {'accepted', 'cancelled'},
    'accepted':    {'in_progress', 'on_hold'},
    'in_progress': {'completed'},
    'completed':   set(),
    'cancelled':   set(),
}


class ServiceRequestService:

    # ── Creation ──────────────────────────────────────────────────────────────

    def create_request(self, user, validated_data, provider=None):
        """Create a new ServiceRequest and write the initial 'pending' tracking row."""
        self.expire_stale_pending_requests()
        if provider and validated_data.get('scheduled_for'):
            self._check_time_conflict(provider, validated_data['scheduled_for'])
        req = ServiceRequest.objects.create(user=user, current_status='pending', **validated_data)
        if provider:
            req.service_provider = provider
            req.save(update_fields=['service_provider'])
        ServiceRequestStatusTracking.objects.create(service_request=req, status='pending')
        return req

    def _check_time_conflict(self, provider, scheduled_for):
        """A provider can't have two active requests scheduled within
        SCHEDULING_CONFLICT_BUFFER of each other."""
        window_start = scheduled_for - SCHEDULING_CONFLICT_BUFFER
        window_end = scheduled_for + SCHEDULING_CONFLICT_BUFFER
        if ServiceRequest.objects.filter(
            service_provider=provider,
            scheduled_for__gt=window_start,
            scheduled_for__lt=window_end,
            current_status__in=('pending', 'on_hold', 'accepted', 'in_progress'),
        ).exists():
            raise ValidationError(
                'This provider already has a request scheduled within '
                '2 hours of that time. Please choose a different time.',
                code='schedule_conflict',
            )

    # ── Expiry ────────────────────────────────────────────────────────────────

    def expire_stale_pending_requests(self):
        """Auto-cancel requests directed at a specific provider that the provider
        didn't accept within PENDING_REQUEST_EXPIRY of creation."""
        from apps.notifications.services import notify_user

        cutoff = timezone.now() - PENDING_REQUEST_EXPIRY
        stale = ServiceRequest.objects.filter(
            current_status='pending',
            service_provider__isnull=False,
            created_at__lt=cutoff,
        )
        for req in stale:
            req.current_status = 'cancelled'
            req.save(update_fields=['current_status'])
            ServiceRequestStatusTracking.objects.create(
                service_request=req, status='cancelled'
            )
            notify_user(
                req.user,
                'request_cancelled',
                'تم إلغاء الطلب تلقائياً',
                f'لم يستجب مزود الخدمة لطلبك ({req.service_type}) خلال ساعة، تم إلغاؤه تلقائياً.',
                related_request_id=req.service_request_id,
            )

    # ── Assignment ────────────────────────────────────────────────────────────

    def assign_provider(self, service_request, provider):
        """SP self-assigns to a pending or on_hold request, transitioning it to 'accepted'."""
        if service_request.current_status not in ('pending', 'on_hold'):
            raise ValidationError(
                f"Can only assign to a pending or on-hold request "
                f"(current status: '{service_request.current_status}')."
            )
        # service_provider may already be set as the user's *requested* provider
        # while status is still pending — that's fine.  Block only if fully accepted.
        if (service_request.service_provider_id and
                service_request.service_provider_id != provider.pk and
                service_request.current_status == 'accepted'):
            raise ValidationError('This request is already assigned to a Service Provider.')
        service_request.service_provider = provider
        service_request.current_status = 'accepted'
        service_request.save(update_fields=['service_provider', 'current_status'])
        ServiceRequestStatusTracking.objects.create(
            service_request=service_request, status='accepted'
        )

    def decline_request(self, service_request, provider):
        """Assigned SP declines the request, putting it on_hold for another provider to pick up."""
        self._check_ownership(service_request, provider)
        self._check_transition(service_request.current_status, 'on_hold')
        service_request.service_provider = None
        service_request.current_status = 'on_hold'
        service_request.save(update_fields=['service_provider', 'current_status'])
        ServiceRequestStatusTracking.objects.create(
            service_request=service_request, status='on_hold'
        )

    # ── Status update (SP only: in_progress / completed) ─────────────────────

    def update_status(self, service_request, new_status, actor_provider):
        """Transition the request to in_progress or completed (assigned SP only)."""
        self._check_ownership(service_request, actor_provider)
        self._check_transition(service_request.current_status, new_status)
        if new_status == 'cancelled':
            raise ValidationError('Use the cancel endpoint to cancel a request.')
        if new_status == 'on_hold':
            raise ValidationError('Use the decline endpoint to put a request on hold.')
        service_request.current_status = new_status
        service_request.save(update_fields=['current_status'])
        ServiceRequestStatusTracking.objects.create(
            service_request=service_request, status=new_status
        )

    # ── Cancellation (Service User only) ─────────────────────────────────────

    def cancel_request(self, service_request, user):
        """Cancel a request before a provider has accepted it (pending/on_hold only)."""
        if service_request.user != user:
            raise PermissionDenied('Only the Service User who created this request can cancel it.')
        if service_request.current_status not in ('pending', 'on_hold'):
            raise ValidationError(
                'This request can no longer be cancelled because a provider has already accepted it.'
            )
        service_request.current_status = 'cancelled'
        service_request.save(update_fields=['current_status'])
        ServiceRequestStatusTracking.objects.create(
            service_request=service_request, status='cancelled'
        )

    # ── Helpers ───────────────────────────────────────────────────────────────

    def _check_transition(self, current, target):
        allowed = VALID_TRANSITIONS.get(current, set())
        if target not in allowed:
            raise ValidationError(
                f"Cannot transition from '{current}' to '{target}'. "
                f"Allowed next states: {sorted(allowed) or 'none'}."
            )

    def _check_ownership(self, service_request, provider):
        if service_request.service_provider != provider:
            raise PermissionDenied(
                'Only the assigned Service Provider can update the status of this request.'
            )


class SavedProviderService:

    def save_provider(self, user, provider):
        obj, created = SavedProvider.objects.get_or_create(user=user, service_provider=provider)
        if not created:
            raise ValidationError('You have already saved this Service Provider.')
        return obj

    def unsave_provider(self, user, provider):
        deleted, _ = SavedProvider.objects.filter(user=user, service_provider=provider).delete()
        if not deleted:
            raise ValidationError('This Service Provider is not in your saved list.')
