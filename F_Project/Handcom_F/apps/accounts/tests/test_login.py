import pytest
import jwt as pyjwt

USER_LOGIN = '/api/v1/auth/service-user/login/'
PROV_LOGIN = '/api/v1/auth/service-provider/login/'
REFRESH_URL = '/api/v1/auth/token/refresh/'


def _decode(token):
    return pyjwt.decode(token, options={'verify_signature': False})


@pytest.mark.django_db
class TestUserLogin:
    def test_success_returns_tokens(self, api_client, create_user):
        create_user(email='ali@test.com', password='Test1234')
        r = api_client.post(USER_LOGIN, {'email': 'ali@test.com', 'password': 'Test1234'})
        assert r.status_code == 200
        assert 'access' in r.data and 'refresh' in r.data

    def test_jwt_carries_service_user_role(self, api_client, create_user):
        create_user(email='ali@test.com', password='Test1234')
        r = api_client.post(USER_LOGIN, {'email': 'ali@test.com', 'password': 'Test1234'})
        payload = _decode(r.data['access'])
        assert payload['role'] == 'service_user'
        assert payload['email'] == 'ali@test.com'

    def test_wrong_password_returns_401(self, api_client, create_user):
        create_user(email='ali@test.com')
        r = api_client.post(USER_LOGIN, {'email': 'ali@test.com', 'password': 'WrongPass1'})
        assert r.status_code == 401

    def test_nonexistent_email_returns_401(self, api_client):
        r = api_client.post(USER_LOGIN, {'email': 'ghost@test.com', 'password': 'Test1234'})
        assert r.status_code == 401

    def test_token_refresh(self, api_client, create_user):
        create_user(email='ali@test.com', password='Test1234')
        login_r = api_client.post(USER_LOGIN, {'email': 'ali@test.com', 'password': 'Test1234'})
        r = api_client.post(REFRESH_URL, {'refresh': login_r.data['refresh']})
        assert r.status_code == 200
        assert 'access' in r.data


@pytest.mark.django_db
class TestServiceProviderLogin:
    def test_success_returns_tokens(self, api_client, create_provider):
        create_provider(email='prov@test.com', password='Test1234')
        r = api_client.post(PROV_LOGIN, {'email': 'prov@test.com', 'password': 'Test1234'})
        assert r.status_code == 200
        assert 'access' in r.data and 'refresh' in r.data

    def test_jwt_carries_service_provider_role(self, api_client, create_provider):
        create_provider(email='prov@test.com', password='Test1234')
        r = api_client.post(PROV_LOGIN, {'email': 'prov@test.com', 'password': 'Test1234'})
        payload = _decode(r.data['access'])
        assert payload['role'] == 'service_provider'
        assert payload['email'] == 'prov@test.com'
        assert 'provider_id' in payload

    def test_wrong_password_returns_401(self, api_client, create_provider):
        create_provider(email='prov@test.com')
        r = api_client.post(PROV_LOGIN, {'email': 'prov@test.com', 'password': 'WrongPass1'})
        assert r.status_code == 401

    def test_nonexistent_email_returns_401(self, api_client):
        r = api_client.post(PROV_LOGIN, {'email': 'ghost@test.com', 'password': 'Test1234'})
        assert r.status_code == 401

    def test_provider_token_refresh(self, api_client, create_provider):
        create_provider(email='prov@test.com', password='Test1234')
        login_r = api_client.post(PROV_LOGIN, {'email': 'prov@test.com', 'password': 'Test1234'})
        r = api_client.post(REFRESH_URL, {'refresh': login_r.data['refresh']})
        assert r.status_code == 200
        assert 'access' in r.data
