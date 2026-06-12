import pytest
from datetime import date, timedelta
from apps.ai_assistant.services import ProviderRecommender

SCHED_URL = '/api/v1/schedules/'
TOMORROW = date.today() + timedelta(days=1)


def _give_schedule(provider_client):
    provider_client.post(SCHED_URL, {
        'working_date': str(TOMORROW),
        'start_time': '09:00',
        'end_time': '17:00',
    })


@pytest.mark.django_db
class TestProviderRecommender:

    def test_returns_providers_with_matching_category(self, provider_client):
        _give_schedule(provider_client)
        results = ProviderRecommender().recommend('plumbing')
        ids = [r['service_provider_id'] for r in results]
        assert provider_client._provider.service_provider_id in ids

    def test_excludes_offline_providers(self, provider_client):
        _give_schedule(provider_client)
        provider_client._provider.availability_status = 'offline'
        provider_client._provider.save()
        results = ProviderRecommender().recommend('plumbing')
        ids = [r['service_provider_id'] for r in results]
        assert provider_client._provider.service_provider_id not in ids

    def test_excludes_providers_without_schedule(self, provider_client):
        # No schedule added — should not appear
        results = ProviderRecommender().recommend('plumbing')
        ids = [r['service_provider_id'] for r in results]
        assert provider_client._provider.service_provider_id not in ids

    def test_excludes_providers_wrong_category(self, provider_client):
        _give_schedule(provider_client)  # provider has ['plumbing']
        results = ProviderRecommender().recommend('electrical')
        ids = [r['service_provider_id'] for r in results]
        assert provider_client._provider.service_provider_id not in ids

    def test_results_sorted_by_rating_when_no_location(self, provider_client, create_provider):
        """Without user coordinates, ranking falls through to rating (service type → location → rating)."""
        _give_schedule(provider_client)

        # Create a second provider with the same category
        from rest_framework.test import APIClient
        p2 = create_provider(email='p2@rec.test', service_categories=['plumbing'])
        c2 = APIClient()
        r = c2.post('/api/v1/auth/service-provider/login/', {'email': 'p2@rec.test', 'password': 'Test1234'})
        c2.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
        c2._provider = p2
        c2.post(SCHED_URL, {
            'working_date': str(TOMORROW), 'start_time': '10:00', 'end_time': '18:00',
        })

        # Give p2 a high rating by creating everything needed
        from apps.services.models import ServiceRequest, ServiceRequestStatusTracking, Service
        from apps.ratings.models import Rating
        from apps.accounts.models import User
        u = User.objects.create_user(
            email='rater@rec.test', full_name='Rater', phone='+962791230000', password='Test1234'
        )
        sr = ServiceRequest.objects.create(
            user=u, service_type='plumbing', location='Amman',
            service_provider=p2, current_status='completed',
        )
        svc = Service.objects.create(
            service_request=sr, service_provider=p2,
            service_name='Plumbing', service_date=date.today(),
        )
        Rating.objects.create(user=u, service_provider=p2, service=svc, rating_value=5)

        results = ProviderRecommender().recommend('plumbing')
        assert len(results) == 2
        assert (results[0]['average_rating'] or 0) >= (results[1]['average_rating'] or 0)
        assert results[0]['service_provider_id'] == p2.service_provider_id

    def test_result_contains_expected_keys(self, provider_client):
        _give_schedule(provider_client)
        results = ProviderRecommender().recommend('plumbing')
        assert len(results) > 0
        r = results[0]
        for key in ('service_provider_id', 'full_name', 'distance_km', 'average_rating', 'total_ratings'):
            assert key in r

    def test_returns_at_most_limit(self, provider_client, create_provider):
        """Seeding 3 plumbers with schedules and requesting limit=2."""
        _give_schedule(provider_client)
        for i in range(2):
            from rest_framework.test import APIClient
            p = create_provider(email=f'lim{i}@rec.test', service_categories=['plumbing'])
            c = APIClient()
            r = c.post('/api/v1/auth/service-provider/login/', {'email': f'lim{i}@rec.test', 'password': 'Test1234'})
            c.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
            c.post(SCHED_URL, {'working_date': str(TOMORROW), 'start_time': '09:00', 'end_time': '17:00'})
        results = ProviderRecommender().recommend('plumbing', limit=2)
        assert len(results) <= 2

