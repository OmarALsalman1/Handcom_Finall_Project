import pytest
from rest_framework.test import APIClient

USER_LOGIN = '/api/v1/auth/service-user/login/'
PROV_LOGIN = '/api/v1/auth/service-provider/login/'


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def create_user(db):
    from apps.accounts.models import User

    def make(**kwargs):
        defaults = {
            'full_name': 'Test User',
            'email': 'user@test.com',
            'phone': '+962791234567',
            'is_email_verified': True,
        }
        defaults.update(kwargs)
        password = defaults.pop('password', 'Test1234')
        return User.objects.create_user(password=password, **defaults)

    return make


@pytest.fixture
def create_provider(db):
    from apps.accounts.models import ServiceProvider

    def make(**kwargs):
        defaults = {
            'full_name': 'Test Provider',
            'email': 'provider@test.com',
            'phone': '+962791234568',
            'experience_years': 3,
            'service_categories': ['plumbing'],
            'is_email_verified': True,
        }
        defaults.update(kwargs)
        password = defaults.pop('password', 'Test1234')
        provider = ServiceProvider(**defaults)
        provider.set_password(password)
        provider.save()
        return provider

    return make


@pytest.fixture
def user_client(db, create_user):
    """Authenticated APIClient for a Service User — always its own APIClient instance."""
    client = APIClient()
    user = create_user(email='utest@handcom.test', password='Test1234')
    r = client.post(USER_LOGIN, {'email': user.email, 'password': 'Test1234'})
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
    client._user = user
    return client


@pytest.fixture
def provider_client(db, create_provider):
    """Authenticated APIClient for a Service Provider — always its own APIClient instance."""
    client = APIClient()
    provider = create_provider(email='ptest@handcom.test', password='Test1234')
    r = client.post(PROV_LOGIN, {'email': provider.email, 'password': 'Test1234'})
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
    client._provider = provider
    return client


@pytest.fixture
def service_request(db, user_client):
    """A pending ServiceRequest owned by the user_client user."""
    r = user_client.post('/api/v1/service-requests/', {
        'service_type': 'plumbing',
        'location': 'Amman, Jordan',
        'description': 'Pipe leaking under sink',
    })
    from apps.services.models import ServiceRequest
    return ServiceRequest.objects.get(pk=r.data['service_request_id'])


@pytest.fixture
def accepted_request(db, user_client, provider_client, service_request):
    """Drives service_request to accepted state and returns it (conversation auto-created)."""
    pk = service_request.service_request_id
    provider_client.post(f'/api/v1/service-requests/{pk}/assign/')
    service_request.refresh_from_db()
    return service_request


@pytest.fixture
def completed_service(db, user_client, provider_client, service_request):
    """
    Drives a ServiceRequest all the way to completed and returns the auto-created Service.
    Depends on user_client / provider_client / service_request sharing the same user/request.
    """
    pk = service_request.service_request_id
    provider_client.post(f'/api/v1/service-requests/{pk}/assign/')
    provider_client.patch(f'/api/v1/service-requests/{pk}/status/', {'status': 'in_progress'})
    provider_client.patch(f'/api/v1/service-requests/{pk}/status/', {'status': 'completed'})

    from apps.services.models import Service
    return Service.objects.get(service_request_id=pk)
