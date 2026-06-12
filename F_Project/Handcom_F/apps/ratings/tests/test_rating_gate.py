import pytest
from apps.ratings.models import Rating

RATINGS_URL = '/api/v1/ratings/'
ASSIGN_URL = lambda pk: f'/api/v1/service-requests/{pk}/assign/'
STATUS_URL = lambda pk: f'/api/v1/service-requests/{pk}/status/'


def _submit(client, service_id, value=5, comment=''):
    return client.post(RATINGS_URL, {
        'service_id': service_id,
        'rating_value': value,
        'rating_comment': comment,
    })


@pytest.mark.django_db
class TestRatingGate:

    def test_rating_happy_path(self, user_client, completed_service):
        r = _submit(user_client, completed_service.service_id)
        assert r.status_code == 201
        assert r.data['rating_value'] == 5

    def test_cannot_rate_non_completed_service(self, user_client, provider_client, service_request):
        """Request is accepted but not completed → no Service exists yet, or status is wrong."""
        pk = service_request.service_request_id
        provider_client.post(ASSIGN_URL(pk))
        # Create a Service manually pointing to an accepted request (edge case simulation)
        from apps.services.models import Service
        import datetime
        svc = Service.objects.create(
            service_request=service_request,
            service_provider=provider_client._provider,
            service_name='Test',
            service_date=datetime.date.today(),
        )
        r = _submit(user_client, svc.service_id)
        assert r.status_code == 400

    def test_cannot_rate_twice(self, user_client, completed_service):
        _submit(user_client, completed_service.service_id, value=4)
        r = _submit(user_client, completed_service.service_id, value=3)
        assert r.status_code == 400

    def test_non_owner_cannot_rate(self, completed_service, create_user):
        """A different user (not the requester) cannot rate the service."""
        from rest_framework.test import APIClient
        other = create_user(email='other@rating.test', password='Test1234')
        other_client = APIClient()
        r = other_client.post('/api/v1/auth/service-user/login/', {
            'email': 'other@rating.test', 'password': 'Test1234'
        })
        other_client.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
        resp = other_client.post(RATINGS_URL, {
            'service_id': completed_service.service_id,
            'rating_value': 5,
        })
        assert resp.status_code == 403

    def test_rating_value_below_1_rejected(self, user_client, completed_service):
        r = _submit(user_client, completed_service.service_id, value=0)
        assert r.status_code == 400

    def test_rating_value_above_5_rejected(self, user_client, completed_service):
        r = _submit(user_client, completed_service.service_id, value=6)
        assert r.status_code == 400

    def test_rating_outside_30_day_window_rejected(self, user_client, completed_service):
        """Back-date the service_date so the window has expired."""
        from datetime import date, timedelta
        completed_service.service_date = date.today() - timedelta(days=31)
        completed_service.save(update_fields=['service_date'])
        r = _submit(user_client, completed_service.service_id)
        assert r.status_code == 400

    def test_provider_cannot_submit_rating(self, provider_client, completed_service):
        r = provider_client.post(RATINGS_URL, {
            'service_id': completed_service.service_id,
            'rating_value': 5,
        })
        assert r.status_code == 403

    def test_unauthenticated_cannot_submit_rating(self, api_client, completed_service):
        r = api_client.post(RATINGS_URL, {
            'service_id': completed_service.service_id,
            'rating_value': 5,
        })
        assert r.status_code == 401
