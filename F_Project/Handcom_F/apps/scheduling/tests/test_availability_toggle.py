import pytest

AVAIL_URL = '/api/v1/service-providers/me/availability/'
ASSIGN_URL = lambda pk: f'/api/v1/service-requests/{pk}/assign/'
STATUS_URL = lambda pk: f'/api/v1/service-requests/{pk}/status/'


@pytest.mark.django_db
class TestAvailabilityToggle:

    def test_toggle_to_offline(self, provider_client):
        r = provider_client.patch(AVAIL_URL, {'availability_status': 'offline'})
        assert r.status_code == 200
        assert r.data['availability_status'] == 'offline'

    def test_toggle_back_to_available(self, provider_client):
        provider_client.patch(AVAIL_URL, {'availability_status': 'offline'})
        r = provider_client.patch(AVAIL_URL, {'availability_status': 'available'})
        assert r.status_code == 200
        assert r.data['availability_status'] == 'available'

    def test_invalid_status_rejected(self, provider_client):
        r = provider_client.patch(AVAIL_URL, {'availability_status': 'flying'})
        assert r.status_code == 400

    def test_cannot_toggle_to_busy_via_endpoint(self, provider_client):
        # 'busy' is system-managed; the endpoint only allows available/offline
        r = provider_client.patch(AVAIL_URL, {'availability_status': 'busy'})
        assert r.status_code == 400

    def test_system_sets_busy_on_in_progress(self, user_client, provider_client, service_request):
        pk = service_request.service_request_id
        provider_client.post(ASSIGN_URL(pk))
        provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})
        provider_client._provider.refresh_from_db()
        assert provider_client._provider.availability_status == 'busy'

    def test_manual_offline_toggle_persists_when_not_in_progress(self, provider_client):
        provider_client.patch(AVAIL_URL, {'availability_status': 'offline'})
        provider_client._provider.refresh_from_db()
        assert provider_client._provider.availability_status == 'offline'

    def test_user_cannot_toggle_provider_availability(self, user_client):
        r = user_client.patch(AVAIL_URL, {'availability_status': 'offline'})
        assert r.status_code == 403
