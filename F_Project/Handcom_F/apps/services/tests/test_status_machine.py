import pytest
from apps.services.models import ServiceRequest, ServiceRequestStatusTracking

SR_URL = '/api/v1/service-requests/'
ASSIGN_URL = lambda pk: f'/api/v1/service-requests/{pk}/assign/'
STATUS_URL = lambda pk: f'/api/v1/service-requests/{pk}/status/'
CANCEL_URL = lambda pk: f'/api/v1/service-requests/{pk}/cancel/'


def _assign_and_advance(provider_client, pk, target='in_progress'):
    provider_client.post(ASSIGN_URL(pk))
    if target in ('in_progress', 'completed'):
        provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})
    if target == 'completed':
        provider_client.patch(STATUS_URL(pk), {'status': 'completed'})


@pytest.mark.django_db
class TestStateMachine:

    def test_invalid_transition_pending_to_completed(self, provider_client, service_request):
        # pending → completed is not allowed (must go pending→accepted→in_progress→completed)
        provider_client.post(ASSIGN_URL(service_request.service_request_id))
        r = provider_client.patch(
            STATUS_URL(service_request.service_request_id), {'status': 'completed'}
        )
        assert r.status_code == 400

    def test_invalid_transition_skipping_accepted(self, provider_client, service_request):
        r = provider_client.patch(
            STATUS_URL(service_request.service_request_id), {'status': 'in_progress'}
        )
        assert r.status_code in (400, 403)

    def test_cannot_transition_completed_request(self, user_client, provider_client, service_request):
        pk = service_request.service_request_id
        _assign_and_advance(provider_client, pk, 'completed')
        r = provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})
        assert r.status_code == 400

    def test_user_cancels_pending_request(self, user_client, service_request):
        r = user_client.patch(CANCEL_URL(service_request.service_request_id))
        assert r.status_code == 200
        assert r.data['current_status'] == 'cancelled'

    def test_user_cannot_cancel_accepted_request(self, user_client, provider_client, service_request):
        pk = service_request.service_request_id
        provider_client.post(ASSIGN_URL(pk))
        r = user_client.patch(CANCEL_URL(pk))
        assert r.status_code == 400
        service_request.refresh_from_db()
        assert service_request.current_status == 'accepted'

    def test_user_cannot_cancel_in_progress_request(self, user_client, provider_client, service_request):
        pk = service_request.service_request_id
        _assign_and_advance(provider_client, pk, 'in_progress')
        r = user_client.patch(CANCEL_URL(pk))
        assert r.status_code == 400

    def test_non_assigned_provider_cannot_update_status(
        self, provider_client, service_request, create_provider, api_client
    ):
        pk = service_request.service_request_id
        provider_client.post(ASSIGN_URL(pk))  # provider_client assigns

        # A second provider tries to change status
        other = create_provider(email='other@test.com')
        from rest_framework.test import APIClient
        other_client = APIClient()
        r = other_client.post('/api/v1/auth/service-provider/login/', {
            'email': 'other@test.com', 'password': 'Test1234'
        })
        other_client.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
        resp = other_client.patch(STATUS_URL(pk), {'status': 'in_progress'})
        assert resp.status_code in (403, 400)

    def test_only_user_can_use_cancel_endpoint(self, provider_client, service_request):
        r = provider_client.patch(CANCEL_URL(service_request.service_request_id))
        assert r.status_code == 403

    def test_status_field_required_on_status_endpoint(self, provider_client, service_request):
        provider_client.post(ASSIGN_URL(service_request.service_request_id))
        r = provider_client.patch(
            STATUS_URL(service_request.service_request_id), {}
        )
        assert r.status_code == 400
