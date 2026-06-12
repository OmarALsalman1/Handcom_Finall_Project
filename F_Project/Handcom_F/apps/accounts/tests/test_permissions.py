import pytest

USER_LOGIN = '/api/v1/auth/service-user/login/'
PROV_LOGIN = '/api/v1/auth/service-provider/login/'
USER_ME = '/api/v1/users/me/'
PROV_ME = '/api/v1/service-providers/me/'


def _user_token(api_client, create_user):
    create_user(email='u@perm.test', password='Test1234')
    r = api_client.post(USER_LOGIN, {'email': 'u@perm.test', 'password': 'Test1234'})
    return r.data['access']


def _provider_token(api_client, create_provider):
    create_provider(email='p@perm.test', password='Test1234')
    r = api_client.post(PROV_LOGIN, {'email': 'p@perm.test', 'password': 'Test1234'})
    return r.data['access']


@pytest.mark.django_db
class TestRolePermissions:
    def test_user_token_accesses_user_me(self, api_client, create_user):
        token = _user_token(api_client, create_user)
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        assert api_client.get(USER_ME).status_code == 200

    def test_provider_token_blocked_from_user_me(self, api_client, create_provider):
        token = _provider_token(api_client, create_provider)
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        assert api_client.get(USER_ME).status_code == 403

    def test_provider_token_accesses_provider_me(self, api_client, create_provider):
        token = _provider_token(api_client, create_provider)
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        assert api_client.get(PROV_ME).status_code == 200

    def test_user_token_blocked_from_provider_me(self, api_client, create_user):
        token = _user_token(api_client, create_user)
        api_client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')
        assert api_client.get(PROV_ME).status_code == 403

    def test_unauthenticated_blocked_from_user_me(self, api_client):
        assert api_client.get(USER_ME).status_code == 401

    def test_unauthenticated_blocked_from_provider_me(self, api_client):
        assert api_client.get(PROV_ME).status_code == 401

    def test_provider_list_is_public(self, api_client):
        assert api_client.get('/api/v1/service-providers/').status_code == 200

    def test_unverified_provider_excluded_from_list(self, api_client, create_provider):
        verified = create_provider(email='verified@perm.test', is_email_verified=True)
        create_provider(email='unverified@perm.test', is_email_verified=False)

        r = api_client.get('/api/v1/service-providers/')
        ids = [p['service_provider_id'] for p in r.data]
        assert verified.service_provider_id in ids
        assert all(p['email'] != 'unverified@perm.test' for p in r.data)
