import pytest
from apps.ai_assistant.services import (
    RuleBasedAIProvider,
    ProblemAnalysis,
    is_negative_feedback,
    build_escalation_analysis,
    solution_follow_up,
)


@pytest.fixture
def provider():
    return RuleBasedAIProvider()


class TestRuleBasedProvider:

    def test_plumbing_keywords_detected(self, provider):
        r = provider.analyze_text('My pipe is leaking under the sink')
        assert r.service_category == 'plumbing'

    def test_electrical_keywords_detected(self, provider):
        r = provider.analyze_text('The electrical wiring in my outlet is sparking')
        assert r.service_category == 'electrical'

    def test_painting_keywords_detected(self, provider):
        r = provider.analyze_text('The paint on my wall is peeling')
        assert r.service_category == 'painting'

    def test_carpentry_keywords_detected(self, provider):
        r = provider.analyze_text('My wooden door hinge is loose')
        assert r.service_category == 'carpentry'

    def test_simple_dripping_faucet_returns_solution(self, provider):
        r = provider.analyze_text('I have a dripping faucet in the kitchen')
        assert r.severity == 'simple'
        assert r.direct_solution is not None
        assert len(r.direct_solution) > 0

    def test_simple_tripped_breaker_returns_solution(self, provider):
        r = provider.analyze_text('The circuit breaker keeps tripping')
        assert r.severity == 'simple'
        assert r.direct_solution is not None

    def test_complex_problem_returns_needs_provider(self, provider):
        r = provider.analyze_text('My main water pipe has burst and the house is flooding')
        assert r.severity == 'needs_provider'
        assert r.direct_solution is None

    def test_result_is_problem_analysis_dataclass(self, provider):
        r = provider.analyze_text('Pipe is leaking')
        assert isinstance(r, ProblemAnalysis)
        assert 0.0 <= r.confidence <= 1.0

    def test_vague_known_category_asks_about_symptom_before_recommending(self, provider):
        # Category is clear (sink → plumbing) but the symptom isn't — the assistant
        # should ask what's wrong with it rather than jump straight to a provider list.
        r = provider.analyze_text('I have a problem with my sink')
        assert r.service_category == 'plumbing'
        assert r.needs_clarification is True
        assert r.severity == 'needs_provider'
        assert r.direct_solution is None

    def test_severe_problem_skips_clarification_and_recommends_directly(self, provider):
        r = provider.analyze_text('My pipe burst and water is flooding the kitchen')
        assert r.service_category == 'plumbing'
        assert r.needs_clarification is False
        assert r.severity == 'needs_provider'
        assert r.direct_solution is None

    def test_unknown_text_asks_for_clarification_instead_of_guessing(self, provider):
        # Vague text shouldn't produce a (likely wrong) category guess + provider
        # suggestion in the same turn — the assistant should ask what's wrong first.
        r = provider.analyze_text('Something is wrong in my house')
        assert r.needs_clarification is True
        assert r.service_category == ''

    def test_image_input_falls_back_to_text_analysis(self, provider):
        r = provider.analyze_image('http://example.com/crack-in-wall.jpg')
        assert isinstance(r, ProblemAnalysis)

    def test_voice_input_falls_back_to_text_analysis(self, provider):
        r = provider.analyze_voice('http://example.com/voice-note.mp3')
        assert isinstance(r, ProblemAnalysis)

    def test_to_dict_is_json_serialisable(self, provider):
        import json
        r = provider.analyze_text('Electrical wiring problem')
        d = r.to_dict()
        assert isinstance(json.dumps(d), str)
        assert 'service_category' in d
        assert 'severity' in d


class TestSolutionFollowUp:

    def test_arabic_follow_up_offers_provider(self):
        msg = solution_follow_up('ar')
        assert 'هل ساعدك' in msg

    def test_english_follow_up_offers_provider(self):
        msg = solution_follow_up('en')
        assert 'Did this solution help' in msg


class TestNegativeFeedbackDetection:

    @pytest.mark.parametrize('text', [
        'لم ينفع', 'ما اشتغل', 'still not working', "didn't work", 'not working',
    ])
    def test_detects_negative_feedback(self, text):
        assert is_negative_feedback(text.lower()) is True

    def test_unrelated_text_is_not_negative_feedback(self):
        assert is_negative_feedback('my pipe is leaking') is False


class TestEscalationAnalysis:

    def test_escalation_targets_same_category_and_recommends_provider(self):
        r = build_escalation_analysis('plumbing', lang='ar')
        assert r.service_category == 'plumbing'
        assert r.severity == 'needs_provider'
        assert r.needs_clarification is False
        assert r.direct_solution is None
