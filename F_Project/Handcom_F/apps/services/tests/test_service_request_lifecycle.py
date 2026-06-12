import pytest
from apps.services.models import ServiceRequest, Service, ServiceRequestStatusTracking

SR_URL = '/api/v1/service-requests/'
ASSIGN_URL = lambda pk: f'/api/v1/service-requests/{pk}/assign/'
STATUS_URL = lambda pk: f'/api/v1/service-requests/{pk}/status/'
TRACKING_URL = lambda pk: f'/api/v1/service-requests/{pk}/tracking/'
SERVICE_URL = '/api/v1/services/'


@pytest.mark.django_db
class TestServiceRequestLifecycle:

    def test_user_creates_request_with_pending_status(self, user_client):
        r = user_client.post(SR_URL, {
            'service_type': 'plumbing',
            'location': 'Amman',
            'description': 'Leaky tap',
        })
        assert r.status_code == 201
        assert r.data['current_status'] == 'pending'

    def test_request_appears_in_user_list(self, user_client, service_request):
        r = user_client.get(SR_URL)
        assert r.status_code == 200
        ids = [item['service_request_id'] for item in r.data]
        assert service_request.service_request_id in ids

    def test_provider_sees_pending_matching_category_request(self, provider_client, service_request):
        # service_request is 'plumbing'; provider_client fixture has categories=['plumbing']
        r = provider_client.get(SR_URL)
        assert r.status_code == 200
        ids = [item['service_request_id'] for item in r.data]
        assert service_request.service_request_id in ids

    def test_provider_assigns_pending_request(self, provider_client, service_request):
        r = provider_client.post(ASSIGN_URL(service_request.service_request_id))
        assert r.status_code == 200
        assert r.data['current_status'] == 'accepted'
        service_request.refresh_from_db()
        assert service_request.service_provider == provider_client._provider

    def test_full_happy_path(self, user_client, provider_client, service_request):
        pk = service_request.service_request_id

        # SP assigns
        provider_client.post(ASSIGN_URL(pk))

        # SP marks in_progress
        r = provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})
        assert r.status_code == 200
        assert r.data['current_status'] == 'in_progress'

        # SP marks completed
        r = provider_client.patch(STATUS_URL(pk), {'status': 'completed'})
        assert r.status_code == 200
        assert r.data['current_status'] == 'completed'

        # Service auto-created by signal
        assert Service.objects.filter(service_request_id=pk).exists()

    def test_tracking_history_records_every_transition(self, provider_client, service_request):
        pk = service_request.service_request_id
        provider_client.post(ASSIGN_URL(pk))
        provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})
        provider_client.patch(STATUS_URL(pk), {'status': 'completed'})

        r = provider_client.get(TRACKING_URL(pk))
        assert r.status_code == 200
        statuses = [t['status'] for t in r.data]
        # History is newest-first; all four statuses must appear
        assert set(statuses) == {'pending', 'accepted', 'in_progress', 'completed'}

    def test_provider_cannot_create_request(self, provider_client):
        r = provider_client.post(SR_URL, {
            'service_type': 'plumbing',
            'location': 'Amman',
        })
        assert r.status_code == 403
