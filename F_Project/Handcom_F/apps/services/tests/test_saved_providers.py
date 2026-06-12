import pytest

SAVE_URL = '/api/v1/saved-providers/add/'
LIST_URL = '/api/v1/saved-providers/'
DELETE_URL = lambda pid: f'/api/v1/saved-providers/{pid}/'


@pytest.mark.django_db
class TestSavedProviders:

    def test_user_saves_provider(self, user_client, create_provider):
        provider = create_provider(email='save1@test.com')
        r = user_client.post(SAVE_URL, {'provider_id': provider.service_provider_id})
        assert r.status_code == 201
        assert r.data['service_provider']['service_provider_id'] == provider.service_provider_id

    def test_duplicate_save_rejected(self, user_client, create_provider):
        provider = create_provider(email='save2@test.com')
        user_client.post(SAVE_URL, {'provider_id': provider.service_provider_id})
        r = user_client.post(SAVE_URL, {'provider_id': provider.service_provider_id})
        assert r.status_code == 400

    def test_list_saved_providers(self, user_client, create_provider):
        p1 = create_provider(email='savep1@test.com')
        p2 = create_provider(email='savep2@test.com')
        user_client.post(SAVE_URL, {'provider_id': p1.service_provider_id})
        user_client.post(SAVE_URL, {'provider_id': p2.service_provider_id})
        r = user_client.get(LIST_URL)
        assert r.status_code == 200
        assert r.data['count'] == 2

    def test_unsave_provider(self, user_client, create_provider):
        provider = create_provider(email='save3@test.com')
        user_client.post(SAVE_URL, {'provider_id': provider.service_provider_id})
        r = user_client.delete(DELETE_URL(provider.service_provider_id))
        assert r.status_code == 204
        # Confirm it's gone
        list_r = user_client.get(LIST_URL)
        assert list_r.data['count'] == 0

    def test_unsave_nonexistent_raises_400(self, user_client, create_provider):
        provider = create_provider(email='save4@test.com')
        r = user_client.delete(DELETE_URL(provider.service_provider_id))
        assert r.status_code == 400

    def test_provider_cannot_access_saved_list(self, provider_client):
        r = provider_client.get(LIST_URL)
        assert r.status_code == 403

    def test_missing_provider_id_returns_400(self, user_client):
        r = user_client.post(SAVE_URL, {})
        assert r.status_code == 400
