import pytest
from apps.ratings.models import Rating

LIST_URL = lambda pk: f'/api/v1/service-providers/{pk}/ratings/'
SUMMARY_URL = lambda pk: f'/api/v1/service-providers/{pk}/ratings/summary/'
RATINGS_URL = '/api/v1/ratings/'


def _make_completed_service(user_client, provider_client, service_type='plumbing'):
    """Helper: creates a completed service and returns its Service object."""
    r = user_client.post('/api/v1/service-requests/', {
        'service_type': service_type,
        'location': 'Test City',
    })
    pk = r.data['service_request_id']
    provider_client.post(f'/api/v1/service-requests/{pk}/assign/')
    provider_client.patch(f'/api/v1/service-requests/{pk}/status/', {'status': 'in_progress'})
    provider_client.patch(f'/api/v1/service-requests/{pk}/status/', {'status': 'completed'})
    from apps.services.models import Service
    return Service.objects.get(service_request_id=pk)


@pytest.mark.django_db
class TestRatingAggregation:

    def test_no_ratings_returns_null_average(self, api_client, create_provider):
        provider = create_provider(email='norating@test.com')
        r = api_client.get(SUMMARY_URL(provider.service_provider_id))
        assert r.status_code == 200
        assert r.data['average'] is None
        assert r.data['total'] == 0

    def test_summary_distribution_correct(self, api_client, user_client, provider_client):
        provider = provider_client._provider
        svc1 = _make_completed_service(user_client, provider_client)
        user_client.post(RATINGS_URL, {'service_id': svc1.service_id, 'rating_value': 5})

        # Need a second user to rate a second service
        from rest_framework.test import APIClient
        from apps.accounts.models import User
        u2 = User.objects.create_user(
            email='u2@agg.test', full_name='U2', phone='+962791234599', password='Test1234'
        )
        c2 = APIClient()
        r = c2.post('/api/v1/auth/service-user/login/', {'email': 'u2@agg.test', 'password': 'Test1234'})
        c2.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")

        svc2 = _make_completed_service(c2, provider_client, service_type='plumbing')
        c2.post(RATINGS_URL, {'service_id': svc2.service_id, 'rating_value': 3})

        r = api_client.get(SUMMARY_URL(provider.service_provider_id))
        assert r.status_code == 200
        assert r.data['total'] == 2
        assert r.data['average'] == 4.0
        assert r.data['distribution']['5'] == 1
        assert r.data['distribution']['3'] == 1
        assert r.data['distribution']['1'] == 0

    def test_list_endpoint_returns_ratings_and_average(self, user_client, provider_client, completed_service):
        user_client.post('/api/v1/ratings/', {
            'service_id': completed_service.service_id,
            'rating_value': 4,
            'rating_comment': 'Good work',
        })
        provider = provider_client._provider
        r = api_client_get = user_client  # any authenticated or public client works
        resp = r.get(LIST_URL(provider.service_provider_id))
        assert resp.status_code == 200
        assert resp.data['total'] == 1
        assert resp.data['average'] == 4.0
        assert len(resp.data['ratings']) == 1
        assert resp.data['ratings'][0]['rating_value'] == 4

    def test_list_endpoint_is_public(self, api_client, create_provider):
        provider = create_provider(email='publist@test.com')
        r = api_client.get(LIST_URL(provider.service_provider_id))
        assert r.status_code == 200

    def test_summary_endpoint_is_public(self, api_client, create_provider):
        provider = create_provider(email='pubsum@test.com')
        r = api_client.get(SUMMARY_URL(provider.service_provider_id))
        assert r.status_code == 200
