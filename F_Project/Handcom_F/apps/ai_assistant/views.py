from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema

from apps.accounts.permissions import IsServiceUser
from apps.services.serializers import ServiceRequestSerializer
from apps.services.services import ServiceRequestService

from .models import AIAssistant, AIConversation, AIMessage
from .serializers import (
    AIConversationSerializer,
    AIConversationListSerializer,
    AIChatInputSerializer,
    AICreateRequestSerializer,
)
from .services import (
    get_ai_provider,
    ProviderRecommender,
    is_negative_feedback,
    wants_provider_now,
    solution_follow_up,
    build_escalation_analysis,
)

_sr_service = ServiceRequestService()
_recommender = ProviderRecommender()


def _get_or_create_ai():
    ai, _ = AIAssistant.objects.get_or_create(
        ai_name='Handcom AI',
        defaults={'purpose': 'Smart problem analysis and provider recommendation'},
    )
    return ai


@extend_schema(tags=['AI'], request=AIChatInputSerializer)
class AIChatView(APIView):
    permission_classes = [IsAuthenticated, IsServiceUser]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def post(self, request):
        serializer = AIChatInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data

        text = d.get('text', '')
        image = d.get('image')
        voice = d.get('voice')
        lang = d.get('lang', 'ar')

        ai = _get_or_create_ai()

        # Continue existing conversation or start a new one
        conv_id = d.get('conversation_id') or request.data.get('conversation_id')
        if conv_id:
            try:
                conversation = AIConversation.objects.get(
                    pk=conv_id, user=request.user
                )
            except AIConversation.DoesNotExist:
                conversation = None
        else:
            conversation = None

        # Analyse the FULL conversation so far (not just this one message) — a rule-based
        # classifier reading each turn in isolation forgets earlier details and corrections,
        # which makes it loop on the same wrong guess and the same clarifying question.
        provider = get_ai_provider()
        if image:
            analysis = provider.analyze_image_file(image, lang=lang)
            input_type = 'image'
        elif voice:
            analysis = provider.analyze_voice_file(voice, lang=lang)
            input_type = 'voice'
        else:
            input_type = 'text'
            last_analysis = conversation.last_analysis if conversation else None
            last_category = (last_analysis or {}).get('service_category')
            text_lower = text.lower()
            if last_category and (
                is_negative_feedback(text_lower) or wants_provider_now(text_lower)
            ):
                # Either the previous DIY fix didn't work, or the user is now
                # explicitly asking for a technician — go straight to provider
                # recommendations for the already-known category instead of
                # re-classifying the whole conversation from scratch (which can
                # make the AI provider repeat the same DIY suggestion).
                analysis = build_escalation_analysis(last_category, lang=lang)
            else:
                if conversation:
                    prior_user_text = ' '.join(
                        conversation.messages.filter(sender='user', input_type='text')
                        .values_list('content', flat=True)
                    )
                    combined_text = f'{prior_user_text} {text}'.strip() if prior_user_text else text
                else:
                    combined_text = text
                analysis = provider.analyze_text(combined_text, lang=lang)

        if conversation:
            conversation.last_analysis = analysis.to_dict()
            conversation.save()

        if not conversation:
            conversation = AIConversation.objects.create(
                user=request.user,
                ai=ai,
                last_analysis=analysis.to_dict(),
            )

        # Save user turn
        AIMessage.objects.create(
            conversation=conversation,
            sender='user',
            input_type=input_type,
            content=text,
        )

        # Build AI text response
        ai_message = analysis.summary
        if analysis.direct_solution:
            ai_message += f'\n\n✅ {analysis.direct_solution}'
            ai_message += solution_follow_up(lang)

        # Save AI turn
        AIMessage.objects.create(
            conversation=conversation,
            sender='ai',
            input_type='text',
            content=ai_message,
        )

        # Only suggest providers once the AI actually knows what kind of problem
        # this is — never alongside a clarifying question about the problem itself.
        recommendations = []
        ready_to_recommend = (
            analysis.severity == 'needs_provider'
            and not analysis.needs_clarification
            and analysis.service_category
        )
        if ready_to_recommend:
            recommendations = _recommender.recommend(
                category=analysis.service_category,
                user_location=request.user.address,
                user_lat=d.get('lat'),
                user_lng=d.get('lng'),
            )

        return Response({
            'conversation_id': conversation.ai_conversation_id,
            'ai_message': ai_message,
            'needs_provider': ready_to_recommend,
            'service_category': analysis.service_category,
            'recommendations': recommendations,
        }, status=status.HTTP_200_OK)


@extend_schema(tags=['AI'], request=AICreateRequestSerializer,
               responses={201: ServiceRequestSerializer})
class AICreateRequestView(APIView):
    permission_classes = [IsAuthenticated, IsServiceUser]

    def post(self, request):
        serializer = AICreateRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data

        conversation = get_object_or_404(
            AIConversation, pk=d['ai_conversation_id'], user=request.user
        )
        if not conversation.last_analysis:
            return Response(
                {
                    'detail': 'No analysis found for this conversation. Send a message describing '
                              'the issue first so the assistant can analyze it.',
                    'code': 'no_analysis_found',
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        analysis = conversation.last_analysis
        req = _sr_service.create_request(
            user=request.user,
            validated_data={
                'service_type': analysis.get('service_category', 'plumbing'),
                'location': d['location'],
                'description': analysis.get('summary', ''),
            },
        )

        provider_id = d.get('service_provider_id')
        if provider_id:
            from apps.accounts.models import ServiceProvider
            try:
                sp = ServiceProvider.objects.get(pk=provider_id)
                # Link the chosen provider but keep status 'pending' — the provider
                # must accept explicitly. Do NOT call assign_provider() here.
                req.service_provider = sp
                req.save(update_fields=['service_provider'])
                from apps.notifications.services import notify_provider
                notify_provider(
                    sp,
                    'new_request',
                    'طلب خدمة جديد',
                    f'لديك طلب جديد من {request.user.full_name} - {req.service_type}',
                    related_request_id=req.service_request_id,
                )
            except ServiceProvider.DoesNotExist:
                pass
            except Exception as e:
                import logging
                logging.getLogger(__name__).warning(
                    'notify_provider failed for provider_id=%s: %s', provider_id, e
                )

        req.refresh_from_db()
        return Response(
            ServiceRequestSerializer(req, context={'request': request}).data,
            status=status.HTTP_201_CREATED,
        )


@extend_schema(tags=['AI'], responses={200: AIConversationListSerializer(many=True)})
class AIConversationListView(APIView):
    permission_classes = [IsAuthenticated, IsServiceUser]

    def get(self, request):
        convs = AIConversation.objects.filter(user=request.user)
        return Response(AIConversationListSerializer(convs, many=True).data)


@extend_schema(tags=['AI'], responses={200: AIConversationSerializer})
class AIConversationDetailView(APIView):
    permission_classes = [IsAuthenticated, IsServiceUser]

    def get(self, request, pk):
        conv = get_object_or_404(AIConversation, pk=pk, user=request.user)
        return Response(AIConversationSerializer(conv).data)
