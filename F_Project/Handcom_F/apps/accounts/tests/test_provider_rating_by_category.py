import pytest
from datetime import date

LIST_URL = '/api/v1/service-providers/'
DETAIL_URL = lambda pk: f'/api/v1/service-providers/{pk}/'


def _add_rating(provider, rater_email, phone, service_type, rating_value, service_category):
    from apps.accounts.models import User
    from apps.services.models import ServiceRequest, Service
    from apps.ratings.models import Rating

    user = User.objects.create_user(
        email=rater_email, full_name='Rater', phone=phone, password='Test1234'
    )
    sr = ServiceRequest.objects.create(
        user=user, service_type=service_type, location='Amman',
        service_provider=provider, current_status='completed',
    )
    svc = Service.objects.create(
        service_request=sr, service_provider=provider,
        service_name=service_type, service_date=date.today(),
    )
    Rating.objects.create(
        user=user, service_provider=provider, service=svc,
        rating_value=rating_value, service_category=service_category,
    )


@pytest.mark.django_db
class TestProviderRatingByCategory:

    def test_list_returns_category_specific_rating(self, api_client, create_provider):
        provider = create_provider(
            email='multi@cat.test', service_categories=['plumbing', 'electrical'],
        )
        _add_rating(provider, 'u1@cat.test', '+962791111111', 'plumbing', 5, 'plumbing')
        _add_rating(provider, 'u2@cat.test', '+962791111112', 'electrical', 1, 'electrical')

        r = api_client.get(f'{LIST_URL}?category=plumbing')
        assert r.status_code == 200
        entry = next(p for p in r.data if p['service_provider_id'] == provider.service_provider_id)
        assert entry['average_rating'] == 5.0
        assert entry['total_ratings'] == 1

        r = api_client.get(f'{LIST_URL}?category=electrical')
        assert r.status_code == 200
        entry = next(p for p in r.data if p['service_provider_id'] == provider.service_provider_id)
        assert entry['average_rating'] == 1.0
        assert entry['total_ratings'] == 1

    def test_list_shows_no_rating_for_category_without_ratings(self, api_client, create_provider):
        provider = create_provider(
            email='fallback@cat.test', service_categories=['plumbing', 'painting'],
        )
        _add_rating(provider, 'u1@fb.test', '+962791111113', 'plumbing', 5, 'plumbing')
        _add_rating(provider, 'u2@fb.test', '+962791111114', 'plumbing', 1, 'plumbing')

        # No ratings for 'painting' yet — must NOT borrow the plumbing average
        r = api_client.get(f'{LIST_URL}?category=painting')
        assert r.status_code == 200
        entry = next(p for p in r.data if p['service_provider_id'] == provider.service_provider_id)
        assert entry['average_rating'] is None
        assert entry['total_ratings'] == 0

    def test_detail_returns_overall_average(self, api_client, create_provider):
        provider = create_provider(
            email='overall@cat.test', service_categories=['plumbing', 'electrical'],
        )
        _add_rating(provider, 'u1@ov.test', '+962791111115', 'plumbing', 5, 'plumbing')
        _add_rating(provider, 'u2@ov.test', '+962791111116', 'electrical', 1, 'electrical')

        r = api_client.get(DETAIL_URL(provider.service_provider_id))
        assert r.status_code == 200
        assert r.data['average_rating'] == 3.0
        assert r.data['total_ratings'] == 2
