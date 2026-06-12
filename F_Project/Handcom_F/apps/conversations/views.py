from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from drf_spectacular.utils import extend_schema, extend_schema_view

from apps.accounts.permissions import IsServiceUser, IsServiceProvider
from apps.services.models import ServiceRequest

from .models import Conversation, Message
from .permissions import IsConversationParticipant
from .serializers import ConversationSerializer, MessageSerializer, MessageCreateSerializer
from .services import ConversationService

_conv_service = ConversationService()


def _get_role(request):
    token = request.auth
    return token.get('role') if token else None


def _get_conversation_or_403(request, pk):
    """Fetch conversation and verify the caller is a participant."""
    conv = get_object_or_404(Conversation, pk=pk)
    perm = IsConversationParticipant()
    if not perm.has_object_permission(request, None, conv):
        from rest_framework.exceptions import PermissionDenied
        raise PermissionDenied(perm.message)
    return conv


# ── Conversation List / Create ────────────────────────────────────────────────

class ConversationListCreateView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = ConversationSerializer

    @extend_schema(tags=['Conversations'], responses={200: ConversationSerializer(many=True)})
    def get(self, request):
        role = _get_role(request)
        if role == 'service_user':
            qs = Conversation.objects.filter(user=request.user)
        elif role == 'service_provider':
            qs = Conversation.objects.filter(service_provider=request.user.provider)
        else:
            qs = Conversation.objects.none()
        return Response(ConversationSerializer(qs, many=True).data)

    @extend_schema(tags=['Conversations'], responses={200: ConversationSerializer, 201: ConversationSerializer})
    def post(self, request):
        if _get_role(request) != 'service_user':
            return Response(
                {'detail': 'Only Service Users can start a conversation.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        service_request_id = request.data.get('service_request_id')
        provider_id = request.data.get('provider_id')

        # ── Direct chat with a provider (no order required) ──────────────────
        if provider_id and not service_request_id:
            from apps.accounts.models import ServiceProvider
            provider = get_object_or_404(ServiceProvider, pk=provider_id)
            # Each user/provider pair shares a single persistent thread
            conv = Conversation.objects.filter(user=request.user, service_provider=provider).first()
            created = False
            if not conv:
                conv = Conversation.objects.create(
                    user=request.user,
                    service_provider=provider,
                    service_request=None,
                )
                created = True
            elif conv.conversation_status == 'closed':
                conv.conversation_status = 'open'
                conv.save(update_fields=['conversation_status'])
            return Response(
                ConversationSerializer(conv).data,
                status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
            )

        # ── Chat linked to a service request ─────────────────────────────────
        if not service_request_id:
            return Response(
                {'detail': "'provider_id' or 'service_request_id' is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        req = get_object_or_404(ServiceRequest, pk=service_request_id, user=request.user)
        if not req.service_provider_id:
            return Response(
                {'detail': 'Request has no assigned Service Provider yet.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        # Reuse (and reopen/repoint) the user's single persistent thread with this provider
        conv = Conversation.objects.filter(user=request.user, service_provider_id=req.service_provider_id).first()
        created = False
        if conv:
            update_fields = []
            if conv.service_request_id != req.pk:
                conv.service_request = req
                update_fields.append('service_request')
            if conv.conversation_status == 'closed':
                conv.conversation_status = 'open'
                update_fields.append('conversation_status')
            if update_fields:
                conv.save(update_fields=update_fields)
        else:
            conv = Conversation.objects.create(
                user=request.user,
                service_provider_id=req.service_provider_id,
                service_request=req,
            )
            created = True
        return Response(
            ConversationSerializer(conv).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


# ── Conversation Detail ───────────────────────────────────────────────────────

@extend_schema(tags=['Conversations'], responses={200: ConversationSerializer})
class ConversationDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        conv = _get_conversation_or_403(request, pk)
        return Response(ConversationSerializer(conv).data)


# ── Close Conversation ────────────────────────────────────────────────────────

@extend_schema(tags=['Conversations'], request=None, responses={200: ConversationSerializer})
class ConversationCloseView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        conv = _get_conversation_or_403(request, pk)
        if conv.conversation_status == 'closed':
            return Response({'detail': 'Conversation is already closed.'})
        conv.conversation_status = 'closed'
        conv.save(update_fields=['conversation_status'])
        return Response(ConversationSerializer(conv).data)


# ── Messages ──────────────────────────────────────────────────────────────────

@extend_schema(tags=['Conversations'], responses={200: MessageSerializer(many=True)})
class MessageListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        conv = _get_conversation_or_403(request, pk)
        ordering = request.query_params.get('ordering', 'asc')
        qs = conv.messages.all()
        if ordering == 'desc':
            qs = qs.order_by('-sent_at')
        return Response(MessageSerializer(qs, many=True).data)


@extend_schema(tags=['Conversations'], request=MessageCreateSerializer,
               responses={201: MessageSerializer})
class MessageCreateView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def post(self, request, pk):
        conv = _get_conversation_or_403(request, pk)
        serializer = MessageCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        role = _get_role(request)
        sender_type = 'user' if role == 'service_user' else 'service_provider'

        message = _conv_service.send_message(
            conversation=conv,
            sender_type=sender_type,
            content=serializer.validated_data['content'],
            attachment=serializer.validated_data.get('attachment'),
        )

        # Notify the other party
        try:
            from apps.notifications.services import notify_user, notify_provider
            if sender_type == 'user':
                notify_provider(
                    conv.service_provider,
                    'new_message',
                    'رسالة جديدة',
                    f'{conv.user.full_name}: {serializer.validated_data["content"][:60]}',
                    related_conversation_id=conv.conversation_id,
                )
            else:
                notify_user(
                    conv.user,
                    'new_message',
                    'رسالة جديدة',
                    f'{conv.service_provider.full_name}: {serializer.validated_data["content"][:60]}',
                    related_conversation_id=conv.conversation_id,
                )
        except Exception:
            pass

        return Response(MessageSerializer(message).data, status=status.HTTP_201_CREATED)
