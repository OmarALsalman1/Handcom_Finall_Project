import pytest
from apps.accounts.services import OTPService

REQUEST_URL = '/api/v1/auth/password-reset/request/'
CONFIRM_URL = '/api/v1/auth/password-reset/confirm/'
USER_LOGIN = '/api/v1/auth/service-user/login/'
PROV_LOGIN = '/api/v1/auth/service-provider/login/'


@pytest.mark.django_db
class TestPasswordResetServiceUser:
    def test_request_always_returns_200(self, api_client, create_user):
        create_user(email='ali@test.com')
        r = api_client.post(REQUEST_URL, {'email': 'ali@test.com', 'role': 'service_user'})
        assert r.status_code == 200

    def test_request_nonexistent_email_still_200(self, api_client):
        # Anti-enumeration: 200 regardless of whether email exists
        r = api_client.post(REQUEST_URL, {'email': 'ghost@test.com', 'role': 'service_user'})
        assert r.status_code == 200

    def test_full_flow_resets_password_and_allows_new_login(self, api_client, create_user):
        create_user(email='ali@test.com', password='OldPass1')
        otp_svc = OTPService()
        code = otp_svc.send('ali@test.com', 'service_user')

        r = api_client.post(CONFIRM_URL, {
            'email': 'ali@test.com',
            'role': 'service_user',
            'otp': code,
            'new_password': 'NewPass123',
        })
        assert r.status_code == 200

        login_r = api_client.post(USER_LOGIN, {
            'email': 'ali@test.com',
            'password': 'NewPass123',
        })
        assert login_r.status_code == 200

    def test_wrong_otp_rejected(self, api_client, create_user):
        create_user(email='ali@test.com')
        OTPService().send('ali@test.com', 'service_user')
        r = api_client.post(CONFIRM_URL, {
            'email': 'ali@test.com',
            'role': 'service_user',
            'otp': '000000',
            'new_password': 'NewPass123',
        })
        assert r.status_code == 400

    def test_otp_cannot_be_reused(self, api_client, create_user):
        create_user(email='ali@test.com', password='OldPass1')
        otp_svc = OTPService()
        code = otp_svc.send('ali@test.com', 'service_user')
        payload = {
            'email': 'ali@test.com',
            'role': 'service_user',
            'otp': code,
            'new_password': 'NewPass123',
        }
        api_client.post(CONFIRM_URL, payload)        # first use — OK
        r2 = api_client.post(CONFIRM_URL, payload)   # second use — must fail
        assert r2.status_code == 400

    def test_weak_new_password_rejected(self, api_client, create_user):
        create_user(email='ali@test.com')
        code = OTPService().send('ali@test.com', 'service_user')
        r = api_client.post(CONFIRM_URL, {
            'email': 'ali@test.com',
            'role': 'service_user',
            'otp': code,
            'new_password': 'weakpass',  # no digit
        })
        assert r.status_code == 400


@pytest.mark.django_db
class TestPasswordResetServiceProvider:
    def test_full_flow(self, api_client, create_provider):
        create_provider(email='prov@test.com', password='OldPass1')
        code = OTPService().send('prov@test.com', 'service_provider')

        r = api_client.post(CONFIRM_URL, {
            'email': 'prov@test.com',
            'role': 'service_provider',
            'otp': code,
            'new_password': 'NewPass123',
        })
        assert r.status_code == 200

        login_r = api_client.post(PROV_LOGIN, {
            'email': 'prov@test.com',
            'password': 'NewPass123',
        })
        assert login_r.status_code == 200
