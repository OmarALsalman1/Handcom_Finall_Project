import pytest
from apps.conversations.models import Conversation, Message

CONV_URL = '/api/v1/conversations/'
CONV_DETAIL = lambda pk: f'/api/v1/conversations/{pk}/'
MSG_LIST = lambda pk: f'/api/v1/conversations/{pk}/messages/'
MSG_SEND = lambda pk: f'/api/v1/conversations/{pk}/messages/send/'


@pytest.mark.django_db
class TestChatFlow:

    def test_conversation_auto_created_on_accept(self, accepted_request):
        assert Conversation.objects.filter(service_request=accepted_request).exists()

    def test_conversation_appears_in_user_list(self, user_client, accepted_request):
        r = user_client.get(CONV_URL)
        assert r.status_code == 200
        ids = [c['conversation_id'] for c in r.data]
        conv = Conversation.objects.get(service_request=accepted_request)
        assert conv.conversation_id in ids

    def test_conversation_appears_in_provider_list(self, provider_client, accepted_request):
        r = provider_client.get(CONV_URL)
        assert r.status_code == 200
        ids = [c['conversation_id'] for c in r.data]
        conv = Conversation.objects.get(service_request=accepted_request)
        assert conv.conversation_id in ids

    def test_user_sends_message(self, user_client, accepted_request):
        conv = Conversation.objects.get(service_request=accepted_request)
        r = user_client.post(MSG_SEND(conv.conversation_id), {'content': 'When can you come?'})
        assert r.status_code == 201
        assert r.data['sender_type'] == 'user'
        assert r.data['content'] == 'When can you come?'

    def test_provider_sends_message(self, provider_client, accepted_request):
        conv = Conversation.objects.get(service_request=accepted_request)
        r = provider_client.post(MSG_SEND(conv.conversation_id), {'content': 'I will be there at 3pm.'})
        assert r.status_code == 201
        assert r.data['sender_type'] == 'service_provider'

    def test_message_list_returns_all_messages(self, user_client, provider_client, accepted_request):
        conv = Conversation.objects.get(service_request=accepted_request)
        user_client.post(MSG_SEND(conv.conversation_id), {'content': 'First message'})
        provider_client.post(MSG_SEND(conv.conversation_id), {'content': 'Second message'})
        r = user_client.get(MSG_LIST(conv.conversation_id))
        assert r.status_code == 200
        assert len(r.data) == 2

    def test_message_list_desc_ordering(self, user_client, provider_client, accepted_request):
        conv = Conversation.objects.get(service_request=accepted_request)
        user_client.post(MSG_SEND(conv.conversation_id), {'content': 'First'})
        provider_client.post(MSG_SEND(conv.conversation_id), {'content': 'Second'})
        r = user_client.get(f'{MSG_LIST(conv.conversation_id)}?ordering=desc')
        assert r.status_code == 200
        assert r.data[0]['content'] == 'Second'

    def test_non_participant_blocked_from_detail(self, accepted_request, create_user):
        from rest_framework.test import APIClient
        conv = Conversation.objects.get(service_request=accepted_request)
        stranger = create_user(email='stranger@test.com', password='Test1234')
        client = APIClient()
        r = client.post('/api/v1/auth/service-user/login/', {'email': 'stranger@test.com', 'password': 'Test1234'})
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
        assert client.get(CONV_DETAIL(conv.conversation_id)).status_code == 403

    def test_non_participant_blocked_from_messages(self, accepted_request, create_user):
        from rest_framework.test import APIClient
        conv = Conversation.objects.get(service_request=accepted_request)
        stranger = create_user(email='stranger2@test.com', password='Test1234')
        client = APIClient()
        r = client.post('/api/v1/auth/service-user/login/', {'email': 'stranger2@test.com', 'password': 'Test1234'})
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {r.data['access']}")
        assert client.post(MSG_SEND(conv.conversation_id), {'content': 'Intruder'}).status_code == 403

    def test_long_message_rejected(self, user_client, accepted_request):
        conv = Conversation.objects.get(service_request=accepted_request)
        r = user_client.post(MSG_SEND(conv.conversation_id), {'content': 'x' * 2001})
        assert r.status_code == 400

    def test_manual_create_conversation_returns_existing(self, user_client, accepted_request):
        """POST /conversations/ when it already exists returns 200, not 201."""
        r = user_client.post(CONV_URL, {'service_request_id': accepted_request.service_request_id})
        assert r.status_code == 200

    def test_manual_create_for_pending_request_rejected(self, user_client, service_request):
        r = user_client.post(CONV_URL, {'service_request_id': service_request.service_request_id})
        assert r.status_code == 400

    def test_unauthenticated_blocked(self, api_client, accepted_request):
        conv = Conversation.objects.get(service_request=accepted_request)
        assert api_client.get(CONV_DETAIL(conv.conversation_id)).status_code == 401
