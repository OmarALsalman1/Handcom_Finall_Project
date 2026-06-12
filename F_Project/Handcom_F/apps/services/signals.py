from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone

from .models import ServiceRequestStatusTracking, ServiceRequest, Service


@receiver(post_save, sender=ServiceRequestStatusTracking)
def on_status_tracking_created(sender, instance, created, **kwargs):
    if not created:
        return

    req = instance.service_request
    new_status = instance.status

    # 1. Sync the denormalised current_status on ServiceRequest
    ServiceRequest.objects.filter(pk=req.pk).update(current_status=new_status)
    req.current_status = new_status  # keep in-memory object consistent

    # 2. Auto-manage ServiceProvider availability
    if req.service_provider_id:
        _update_provider_availability(req, new_status)

    # 3. Auto-create Conversation when request is accepted
    if new_status == 'accepted' and req.service_provider_id:
        _auto_create_conversation(req)

    # 4. Auto-create Service record when work is completed
    if new_status == 'completed' and req.service_provider_id:
        Service.objects.get_or_create(
            service_request=req,
            defaults={
                'service_provider_id': req.service_provider_id,
                'service_name': req.service_type,
                'service_date': timezone.now().date(),
                'service_description': req.description or '',
            },
        )

    # 5. Auto-close any linked Conversation on terminal states
    if new_status in ('completed', 'cancelled'):
        _close_conversation(req)


def _update_provider_availability(req, new_status):
    from apps.accounts.models import ServiceProvider
    try:
        provider = ServiceProvider.objects.get(pk=req.service_provider_id)
    except ServiceProvider.DoesNotExist:
        return

    if new_status == 'in_progress':
        provider.availability_status = 'busy'
        provider.save(update_fields=['availability_status'])

    elif new_status in ('completed', 'cancelled'):
        still_busy = ServiceRequest.objects.filter(
            service_provider=provider,
            current_status='in_progress',
        ).exclude(pk=req.pk).exists()
        if not still_busy and provider.availability_status == 'busy':
            provider.availability_status = 'available'
            provider.save(update_fields=['availability_status'])


def _auto_create_conversation(req):
    """Reuse the single persistent thread between this user and provider, reopening it
    and pointing it at the latest request, or create one if they've never chatted."""
    try:
        from apps.conversations.models import Conversation
        conv = Conversation.objects.filter(
            user_id=req.user_id, service_provider_id=req.service_provider_id
        ).first()
        if conv:
            update_fields = []
            if conv.service_request_id != req.pk:
                conv.service_request = req
                update_fields.append('service_request')
            if conv.conversation_status != 'open':
                conv.conversation_status = 'open'
                update_fields.append('conversation_status')
            if update_fields:
                conv.save(update_fields=update_fields)
        else:
            Conversation.objects.create(
                user_id=req.user_id,
                service_provider_id=req.service_provider_id,
                service_request=req,
                conversation_status='open',
            )
    except Exception:
        pass


def _close_conversation(req):
    """Close the shared thread only if this user has no other ongoing request
    with the same provider — otherwise the persistent thread stays open."""
    try:
        from apps.conversations.models import Conversation
        still_active = ServiceRequest.objects.filter(
            user_id=req.user_id,
            service_provider_id=req.service_provider_id,
            current_status__in=('accepted', 'in_progress', 'on_hold'),
        ).exclude(pk=req.pk).exists()
        if still_active:
            return
        conv = Conversation.objects.filter(
            user_id=req.user_id, service_provider_id=req.service_provider_id
        ).first()
        if conv and conv.conversation_status == 'open':
            conv.conversation_status = 'closed'
            conv.save(update_fields=['conversation_status'])
    except Exception:
        pass
