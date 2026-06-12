import pytest
from datetime import date, timedelta

SCHED_URL = '/api/v1/schedules/'
SCHED_ME = '/api/v1/schedules/me/'
SCHED_DETAIL = lambda pk: f'/api/v1/schedules/{pk}/'
PUBLIC_SCHED = lambda pk: f'/api/v1/service-providers/{pk}/schedule/'

TOMORROW = str(date.today() + timedelta(days=1))
NEXT_WEEK = str(date.today() + timedelta(days=7))
YESTERDAY = str(date.today() - timedelta(days=1))


def _slot(client, start, end, day=TOMORROW):
    return client.post(SCHED_URL, {'working_date': day, 'start_time': start, 'end_time': end})


@pytest.mark.django_db
class TestOverlapDetection:

    def test_create_slot_success(self, provider_client):
        r = _slot(provider_client, '09:00', '11:00')
        assert r.status_code == 201
        assert r.data['start_time'] == '09:00:00'

    def test_non_overlapping_back_to_back_slots_allowed(self, provider_client):
        _slot(provider_client, '09:00', '10:00')
        r = _slot(provider_client, '10:00', '11:00')  # starts exactly when previous ends
        assert r.status_code == 201

    def test_non_overlapping_different_days_allowed(self, provider_client):
        _slot(provider_client, '09:00', '11:00', day=TOMORROW)
        r = _slot(provider_client, '09:00', '11:00', day=NEXT_WEEK)
        assert r.status_code == 201

    def test_overlapping_slot_rejected(self, provider_client):
        _slot(provider_client, '09:00', '12:00')
        r = _slot(provider_client, '11:00', '13:00')  # overlaps 11:00-12:00
        assert r.status_code == 400

    def test_contained_slot_rejected(self, provider_client):
        _slot(provider_client, '09:00', '17:00')
        r = _slot(provider_client, '10:00', '11:00')  # fully inside
        assert r.status_code == 400

    def test_surrounding_slot_rejected(self, provider_client):
        _slot(provider_client, '10:00', '11:00')
        r = _slot(provider_client, '09:00', '12:00')  # surrounds existing
        assert r.status_code == 400

    def test_identical_slot_rejected(self, provider_client):
        _slot(provider_client, '09:00', '11:00')
        r = _slot(provider_client, '09:00', '11:00')
        assert r.status_code == 400

    def test_past_date_rejected(self, provider_client):
        r = _slot(provider_client, '09:00', '11:00', day=YESTERDAY)
        assert r.status_code == 400

    def test_end_before_start_rejected(self, provider_client):
        r = _slot(provider_client, '11:00', '09:00')
        assert r.status_code == 400

    def test_end_equals_start_rejected(self, provider_client):
        r = _slot(provider_client, '10:00', '10:00')
        assert r.status_code == 400

    def test_my_schedule_returns_own_slots(self, provider_client):
        _slot(provider_client, '09:00', '10:00')
        _slot(provider_client, '14:00', '16:00')
        r = provider_client.get(SCHED_ME)
        assert r.status_code == 200
        assert len(r.data) == 2

    def test_update_slot_no_overlap(self, provider_client):
        r1 = _slot(provider_client, '09:00', '10:00')
        pk = r1.data['service_provider_schedule_id']
        r = provider_client.put(SCHED_DETAIL(pk), {
            'working_date': TOMORROW, 'start_time': '14:00', 'end_time': '15:00',
        })
        assert r.status_code == 200
        assert r.data['start_time'] == '14:00:00'

    def test_update_slot_overlap_with_other_rejected(self, provider_client):
        _slot(provider_client, '13:00', '14:00')  # second slot
        r1 = _slot(provider_client, '09:00', '10:00')
        pk = r1.data['service_provider_schedule_id']
        r = provider_client.put(SCHED_DETAIL(pk), {
            'working_date': TOMORROW, 'start_time': '13:00', 'end_time': '14:30',
        })
        assert r.status_code == 400

    def test_update_slot_self_allowed(self, provider_client):
        """Updating a slot to the same times should succeed (not overlap with itself)."""
        r1 = _slot(provider_client, '09:00', '10:00')
        pk = r1.data['service_provider_schedule_id']
        r = provider_client.put(SCHED_DETAIL(pk), {
            'working_date': TOMORROW, 'start_time': '09:00', 'end_time': '10:30',
        })
        assert r.status_code == 200

    def test_delete_slot(self, provider_client):
        r1 = _slot(provider_client, '09:00', '10:00')
        pk = r1.data['service_provider_schedule_id']
        r = provider_client.delete(SCHED_DETAIL(pk))
        assert r.status_code == 204

    def test_another_provider_cannot_delete_slot(self, provider_client, create_provider):
        r1 = _slot(provider_client, '09:00', '10:00')
        pk = r1.data['service_provider_schedule_id']

        from rest_framework.test import APIClient
        other = create_provider(email='other_sched@test.com', password='Test1234')
        c2 = APIClient()
        r = c2.post('/api/v1/auth/service-provider/login/', {'email': 'other_sched@test.com', 'password': 'Test1234'})
        c2.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
        assert c2.delete(SCHED_DETAIL(pk)).status_code == 403

    def test_public_schedule_returns_only_next_14_days(self, provider_client):
        # Slot tomorrow (within window)
        _slot(provider_client, '09:00', '10:00', day=TOMORROW)
        # Slot 20 days out (outside window)
        far_future = str(date.today() + timedelta(days=20))
        _slot(provider_client, '09:00', '10:00', day=far_future)

        provider = provider_client._provider
        r = provider_client.get(PUBLIC_SCHED(provider.service_provider_id))
        assert r.status_code == 200
        assert len(r.data) == 1
        assert r.data[0]['working_date'] == TOMORROW

    def test_public_schedule_is_accessible_unauthenticated(self, api_client, create_provider):
        provider = create_provider(email='pub_sched@test.com')
        r = api_client.get(PUBLIC_SCHED(provider.service_provider_id))
        assert r.status_code == 200

    def test_user_cannot_create_schedule(self, user_client):
        r = _slot(user_client, '09:00', '10:00')
        assert r.status_code == 403
