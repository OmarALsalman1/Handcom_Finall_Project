import pytest

USER_URL = '/api/v1/auth/service-user/register/'
PROV_URL = '/api/v1/auth/service-provider/register/'


@pytest.mark.django_db
class TestUserRegistration:
    def test_success(self, api_client):
        r = api_client.post(USER_URL, {
            'full_name': 'Ali Hassan',
            'email': 'ali@test.com',
            'phone': '+962791234567',
            'password': 'Secure123',
        })
        assert r.status_code == 201
        assert r.data['email'] == 'ali@test.com'

    def test_duplicate_email(self, api_client, create_user):
        create_user(email='ali@test.com')
        r = api_client.post(USER_URL, {
            'full_name': 'Ali Again',
            'email': 'ali@test.com',
            'phone': '+962791234568',
            'password': 'Secure123',
        })
        assert r.status_code == 400

    def test_weak_password_no_digit(self, api_client):
        r = api_client.post(USER_URL, {
            'full_name': 'Ali',
            'email': 'ali@test.com',
            'phone': '+962791234567',
            'password': 'nodigitpass',
        })
        assert r.status_code == 400

    def test_weak_password_too_short(self, api_client):
        r = api_client.post(USER_URL, {
            'full_name': 'Ali',
            'email': 'ali@test.com',
            'phone': '+962791234567',
            'password': 'Ab1',
        })
        assert r.status_code == 400

    def test_weak_password_no_letter(self, api_client):
        r = api_client.post(USER_URL, {
            'full_name': 'Ali',
            'email': 'ali@test.com',
            'phone': '+962791234567',
            'password': '12345678',
        })
        assert r.status_code == 400

    def test_invalid_phone(self, api_client):
        r = api_client.post(USER_URL, {
            'full_name': 'Ali',
            'email': 'ali@test.com',
            'phone': 'abc-invalid',
            'password': 'Secure123',
        })
        assert r.status_code == 400

    def test_optional_address(self, api_client):
        r = api_client.post(USER_URL, {
            'full_name': 'Ali',
            'email': 'ali2@test.com',
            'phone': '+962791234567',
            'password': 'Secure123',
            'address': 'Amman, Jordan',
        })
        assert r.status_code == 201


@pytest.mark.django_db
class TestServiceProviderRegistration:
    def _valid_payload(self, **overrides):
        data = {
            'full_name': 'Ahmad Plumber',
            'email': 'ahmad@test.com',
            'phone': '+962791234569',
            'password': 'Secure123',
            'experience_years': 5,
            'service_categories': ['plumbing', 'carpentry'],
        }
        data.update(overrides)
        return data

    def test_success(self, api_client):
        r = api_client.post(PROV_URL, self._valid_payload(), format='json')
        assert r.status_code == 201
        assert r.data['email'] == 'ahmad@test.com'

    def test_invalid_category(self, api_client):
        r = api_client.post(
            PROV_URL,
            self._valid_payload(service_categories=['plumbing', 'magic_spells']),
            format='json',
        )
        assert r.status_code == 400

    def test_empty_categories_rejected(self, api_client):
        r = api_client.post(
            PROV_URL,
            self._valid_payload(service_categories=[]),
            format='json',
        )
        assert r.status_code == 400

    def test_duplicate_email(self, api_client, create_provider):
        create_provider(email='ahmad@test.com')
        r = api_client.post(PROV_URL, self._valid_payload(), format='json')
        assert r.status_code == 400

    def test_weak_password(self, api_client):
        r = api_client.post(
            PROV_URL,
            self._valid_payload(password='weakpass'),
            format='json',
        )
        assert r.status_code == 400

    def test_all_valid_categories_accepted(self, api_client):
        r = api_client.post(PROV_URL, self._valid_payload(
            service_categories=['plumbing', 'electrical', 'painting', 'carpentry'],
        ), format='json')
        assert r.status_code == 201
