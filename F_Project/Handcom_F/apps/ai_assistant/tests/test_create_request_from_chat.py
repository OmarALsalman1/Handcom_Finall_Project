import pytest
from django.test import override_settings

AI_CHAT_URL = '/api/v1/ai/chat/'
AI_CREATE_URL = '/api/v1/ai/create-request/'
AI_LIST_URL = '/api/v1/ai/conversations/'
AI_DETAIL_URL = lambda pk: f'/api/v1/ai/conversations/{pk}/'


@pytest.mark.django_db
class TestAIChatEndpoint:

    def test_chat_returns_analysis(self, user_client):
        r = user_client.post(AI_CHAT_URL, {'text': 'My pipe is leaking badly'})
        assert r.status_code == 200
        assert 'service_category' in r.data
        assert r.data['service_category'] == 'plumbing'

    def test_chat_simple_problem_returns_direct_solution(self, user_client):
        r = user_client.post(AI_CHAT_URL, {'text': 'I have a dripping faucet'})
        assert r.status_code == 200
        # Simple problems: not flagged as needing a provider, and solution is in ai_message
        assert not r.data['needs_provider']
        assert r.data['ai_message']
        assert r.data['recommendations'] == []

    @override_settings(AI_PROVIDER='rule_based')
    def test_chat_simple_solution_asks_if_it_helped(self, user_client):
        r = user_client.post(AI_CHAT_URL, {'text': 'I have a dripping faucet'})
        assert r.status_code == 200
        assert 'هل ساعدك هذا الحل' in r.data['ai_message']

    @override_settings(AI_PROVIDER='rule_based')
    def test_negative_feedback_after_simple_solution_escalates_to_provider(self, user_client):
        r1 = user_client.post(AI_CHAT_URL, {'text': 'I have a dripping faucet'})
        assert not r1.data['needs_provider']
        conv_id = r1.data['conversation_id']

        r2 = user_client.post(
            AI_CHAT_URL, {'text': 'لم ينفع', 'conversation_id': conv_id}
        )
        assert r2.status_code == 200
        assert r2.data['needs_provider']
        assert r2.data['service_category'] == 'plumbing'

    @override_settings(AI_PROVIDER='rule_based')
    def test_explicit_provider_request_after_simple_solution_escalates(self, user_client):
        r1 = user_client.post(AI_CHAT_URL, {'text': 'I have a dripping faucet'})
        assert not r1.data['needs_provider']
        conv_id = r1.data['conversation_id']

        r2 = user_client.post(
            AI_CHAT_URL, {'text': 'أبغى فني', 'conversation_id': conv_id}
        )
        assert r2.status_code == 200
        assert r2.data['needs_provider']
        assert r2.data['service_category'] == 'plumbing'

    def test_chat_complex_problem_returns_recommendations_format(self, user_client):
        r = user_client.post(AI_CHAT_URL, {'text': 'All electrical wiring in the house is faulty'})
        assert r.status_code == 200
        # Complex problems: needs_provider is truthy (service_category string or True)
        assert r.data['needs_provider']
        assert 'recommendations' in r.data
        assert isinstance(r.data['recommendations'], list)

    def test_chat_creates_ai_conversation_record(self, user_client):
        from apps.ai_assistant.models import AIConversation
        before = AIConversation.objects.count()
        user_client.post(AI_CHAT_URL, {'text': 'My wall paint is peeling'})
        assert AIConversation.objects.count() == before + 1

    def test_chat_saves_two_messages_per_turn(self, user_client):
        from apps.ai_assistant.models import AIMessage, AIConversation
        r = user_client.post(AI_CHAT_URL, {'text': 'Pipe is leaking'})
        conv_id = r.data['conversation_id']
        conv = AIConversation.objects.get(pk=conv_id)
        assert conv.messages.count() == 2
        senders = set(conv.messages.values_list('sender', flat=True))
        assert senders == {'user', 'ai'}

    def test_chat_no_input_returns_400(self, user_client):
        r = user_client.post(AI_CHAT_URL, {})
        assert r.status_code == 400

    def test_provider_cannot_use_ai_chat(self, provider_client):
        r = provider_client.post(AI_CHAT_URL, {'text': 'Pipe leaking'})
        assert r.status_code == 403

    def test_unauthenticated_blocked(self, api_client):
        r = api_client.post(AI_CHAT_URL, {'text': 'Pipe leaking'})
        assert r.status_code == 401

    def test_conversation_list_returns_my_conversations(self, user_client):
        user_client.post(AI_CHAT_URL, {'text': 'Pipe leaking'})
        user_client.post(AI_CHAT_URL, {'text': 'Electrical issue'})
        r = user_client.get(AI_LIST_URL)
        assert r.status_code == 200
        assert len(r.data) == 2

    def test_conversation_detail_includes_messages(self, user_client):
        chat_r = user_client.post(AI_CHAT_URL, {'text': 'Pipe leaking'})
        conv_id = chat_r.data['conversation_id']
        r = user_client.get(AI_DETAIL_URL(conv_id))
        assert r.status_code == 200
        assert 'messages' in r.data
        assert len(r.data['messages']) == 2


@pytest.mark.django_db
class TestAICreateRequest:

    def test_creates_service_request_from_chat(self, user_client):
        chat_r = user_client.post(AI_CHAT_URL, {'text': 'My pipe is leaking'})
        conv_id = chat_r.data['conversation_id']
        r = user_client.post(AI_CREATE_URL, {
            'ai_conversation_id': conv_id,
            'location': 'Amman, Jordan',
        })
        assert r.status_code == 201
        assert r.data['service_type'] == 'plumbing'
        assert r.data['current_status'] == 'pending'

    def test_create_request_pre_assigns_provider(self, user_client, provider_client):
        chat_r = user_client.post(AI_CHAT_URL, {'text': 'My pipe is leaking'})
        conv_id = chat_r.data['conversation_id']
        provider = provider_client._provider
        r = user_client.post(AI_CREATE_URL, {
            'ai_conversation_id': conv_id,
            'location': 'Amman',
            'service_provider_id': provider.service_provider_id,
        })
        assert r.status_code == 201
        assert r.data['current_status'] == 'accepted'

    def test_create_request_wrong_conversation_returns_404(self, user_client):
        r = user_client.post(AI_CREATE_URL, {
            'ai_conversation_id': 999,
            'location': 'Amman',
        })
        assert r.status_code == 404

    def test_provider_cannot_create_request_from_chat(self, provider_client):
        r = provider_client.post(AI_CREATE_URL, {
            'ai_conversation_id': 1,
            'location': 'Amman',
        })
        assert r.status_code == 403


@pytest.mark.django_db
class TestProviderNotInstantiatedWhenRuleBased:

    def test_get_ai_provider_returns_rule_based_by_default(self):
        from apps.ai_assistant.services import get_ai_provider, RuleBasedAIProvider, GeminiAIProvider
        with override_settings(AI_PROVIDER='rule_based'):
            p = get_ai_provider()
        assert isinstance(p, RuleBasedAIProvider)
        assert not isinstance(p, GeminiAIProvider)

    def test_gemini_provider_raises_without_api_key(self):
        from apps.ai_assistant.services import GeminiAIProvider
        with override_settings(GEMINI_API_KEY=''):
            with pytest.raises(ValueError, match='GEMINI_API_KEY'):
                GeminiAIProvider()
