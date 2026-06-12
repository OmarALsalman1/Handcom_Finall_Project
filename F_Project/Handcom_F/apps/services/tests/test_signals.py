import pytest
from apps.services.models import ServiceRequest, Service, ServiceRequestStatusTracking
from apps.accounts.models import ServiceProvider

ASSIGN_URL = lambda pk: f'/api/v1/service-requests/{pk}/assign/'
STATUS_URL = lambda pk: f'/api/v1/service-requests/{pk}/status/'


def _full_flow(provider_client, service_request, up_to='completed'):
    pk = service_request.service_request_id
    provider_client.post(ASSIGN_URL(pk))
    if up_to in ('in_progress', 'completed'):
        provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})
    if up_to == 'completed':
        provider_client.patch(STATUS_URL(pk), {'status': 'completed'})


@pytest.mark.django_db
class TestSignals:

    def test_current_status_synced_on_each_transition(self, provider_client, service_request):
        pk = service_request.service_request_id
        provider_client.post(ASSIGN_URL(pk))
        service_request.refresh_from_db()
        assert service_request.current_status == 'accepted'

        provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})
        service_request.refresh_from_db()
        assert service_request.current_status == 'in_progress'

    def test_provider_goes_busy_on_in_progress(self, provider_client, service_request):
        pk = service_request.service_request_id
        provider_client.post(ASSIGN_URL(pk))
        provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})

        provider_client._provider.refresh_from_db()
        assert provider_client._provider.availability_status == 'busy'

    def test_provider_returns_available_on_completed(self, provider_client, service_request):
        _full_flow(provider_client, service_request, 'completed')
        provider_client._provider.refresh_from_db()
        assert provider_client._provider.availability_status == 'available'

    def test_provider_stays_busy_if_other_in_progress_request_exists(
        self, user_client, provider_client, service_request, create_user
    ):
        """Provider with TWO in-progress requests: completing one should NOT flip to available."""
        # Create a second request and assign it to the same provider
        u2 = create_user(email='u2@test.com')
        from apps.services.models import ServiceRequest as SR, ServiceRequestStatusTracking as SRT
        req2 = SR.objects.create(
            user=u2, service_type='plumbing', location='Zarqa',
            service_provider=provider_client._provider, current_status='accepted',
        )
        SRT.objects.create(service_request=req2, status='pending')
        SRT.objects.create(service_request=req2, status='accepted')
        SRT.objects.create(service_request=req2, status='in_progress')  # this triggers busy
        req2.refresh_from_db()

        # Also push first request to in_progress
        pk = service_request.service_request_id
        provider_client.post(ASSIGN_URL(pk))
        provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})

        # Complete first request
        provider_client.patch(STATUS_URL(pk), {'status': 'completed'})

        # Provider still has req2 in_progress → must remain busy
        provider_client._provider.refresh_from_db()
        assert provider_client._provider.availability_status == 'busy'

    def test_service_auto_created_on_completion(self, provider_client, service_request):
        _full_flow(provider_client, service_request, 'completed')
        assert Service.objects.filter(service_request=service_request).exists()

    def test_service_not_created_before_completion(self, provider_client, service_request):
        pk = service_request.service_request_id
        provider_client.post(ASSIGN_URL(pk))
        provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})
        assert not Service.objects.filter(service_request=service_request).exists()

    def test_provider_availability_not_changed_on_cancellation(
        self, user_client, provider_client, service_request
    ):
        """Cancel from accepted — provider was never busy, must stay available."""
        pk = service_request.service_request_id
        provider_client.post(ASSIGN_URL(pk))
        user_client.patch(f'/api/v1/service-requests/{pk}/cancel/')
        provider_client._provider.refresh_from_db()
        assert provider_client._provider.availability_status == 'available'
