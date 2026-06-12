import pytest
from apps.conversations.models import Conversation

MSG_SEND = lambda pk: f'/api/v1/conversations/{pk}/messages/send/'
CLOSE_URL = lambda pk: f'/api/v1/conversations/{pk}/close/'
ASSIGN_URL = lambda pk: f'/api/v1/service-requests/{pk}/assign/'
STATUS_URL = lambda pk: f'/api/v1/service-requests/{pk}/status/'
CANCEL_URL = lambda pk: f'/api/v1/service-requests/{pk}/cancel/'


@pytest.mark.django_db
class TestAutoClose:

    def test_conversation_auto_closes_on_completion(self, user_client, provider_client, accepted_request):
        pk = accepted_request.service_request_id
        provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})
        provider_client.patch(STATUS_URL(pk), {'status': 'completed'})

        conv = Conversation.objects.get(service_request=accepted_request)
        assert conv.conversation_status == 'closed'

    def test_conversation_auto_closes_on_cancellation(self, user_client, provider_client, accepted_request):
        # Cancel from accepted state
        user_client.patch(CANCEL_URL(accepted_request.service_request_id))
        conv = Conversation.objects.get(service_request=accepted_request)
        assert conv.conversation_status == 'closed'

    def test_cannot_send_message_to_closed_conversation(
        self, user_client, provider_client, accepted_request
    ):
        pk = accepted_request.service_request_id
        provider_client.patch(STATUS_URL(pk), {'status': 'in_progress'})
        provider_client.patch(STATUS_URL(pk), {'status': 'completed'})

        conv = Conversation.objects.get(service_request=accepted_request)
        r = user_client.post(MSG_SEND(conv.conversation_id), {'content': 'Too late!'})
        assert r.status_code == 400

    def test_manual_close_works(self, user_client, accepted_request):
        conv = Conversation.objects.get(service_request=accepted_request)
        r = user_client.patch(CLOSE_URL(conv.conversation_id))
        assert r.status_code == 200
        conv.refresh_from_db()
        assert conv.conversation_status == 'closed'

    def test_manual_close_by_provider_works(self, provider_client, accepted_request):
        conv = Conversation.objects.get(service_request=accepted_request)
        r = provider_client.patch(CLOSE_URL(conv.conversation_id))
        assert r.status_code == 200
        conv.refresh_from_db()
        assert conv.conversation_status == 'closed'

    def test_closing_already_closed_is_idempotent(self, user_client, accepted_request):
        conv = Conversation.objects.get(service_request=accepted_request)
        user_client.patch(CLOSE_URL(conv.conversation_id))
        r = user_client.patch(CLOSE_URL(conv.conversation_id))
        assert r.status_code == 200

    def test_non_participant_cannot_close(self, accepted_request, create_user):
        from rest_framework.test import APIClient
        conv = Conversation.objects.get(service_request=accepted_request)
        stranger = create_user(email='stranger3@test.com', password='Test1234')
        client = APIClient()
        r = client.post('/api/v1/auth/service-user/login/', {'email': 'stranger3@test.com', 'password': 'Test1234'})
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
        assert client.patch(CLOSE_URL(conv.conversation_id)).status_code == 403
