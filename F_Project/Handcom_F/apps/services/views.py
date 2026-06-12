from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from drf_spectacular.utils import extend_schema

from apps.accounts.models import ServiceProvider
from apps.accounts.permissions import IsServiceUser, IsServiceProvider, IsOwnerOrAssignedProvider

from .models import ServiceRequest, Service, ServiceRequestStatusTracking, SavedProvider
from .serializers import (
    ServiceRequestCreateSerializer,
    ServiceRequestSerializer,
    ServiceSerializer,
    ServiceCreateSerializer,
    ServiceRequestStatusTrackingSerializer,
    SavedProviderSerializer,
)
from .services import ServiceRequestService, SavedProviderService

_sr_service = ServiceRequestService()
_sp_service = SavedProviderService()


# ── Service Requests ──────────────────────────────────────────────────────────

@extend_schema(tags=['Service Requests'], request=ServiceRequestCreateSerializer,
               responses={200: ServiceRequestSerializer(many=True), 201: ServiceRequestSerializer})
class ServiceRequestListCreateView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get(self, request):
        _sr_service.expire_stale_pending_requests()
        token = request.auth
        role = token.get('role') if token else None

        if role == 'service_user':
            qs = ServiceRequest.objects.filter(user=request.user)
        else:
            provider = request.user.provider
            if request.query_params.get('incoming') == 'true':
                # Provider home page: requests the user directed at this provider,
                # waiting for them to accept or decline.
                qs = ServiceRequest.objects.filter(
                    service_provider=provider,
                    current_status__in=['pending', 'on_hold'],
                )
            else:
                # "My Jobs" (طلباتي) — only jobs the provider has actively accepted.
                qs = ServiceRequest.objects.filter(
                    service_provider=provider,
                    current_status__in=['accepted', 'in_progress', 'completed'],
                )

        serializer = ServiceRequestSerializer(qs, many=True, context={'request': request})
        return Response(serializer.data)

    def post(self, request):
        if not (request.auth and request.auth.get('role') == 'service_user'):
            return Response(
                {'detail': 'Only Service Users can create requests.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        serializer = ServiceRequestCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Resolve the chosen provider up front so create_request can check for
        # a scheduling conflict before the request row is ever created.
        provider = None
        provider_id = request.data.get('provider_id')
        if provider_id:
            try:
                provider = ServiceProvider.objects.get(pk=provider_id)
            except ServiceProvider.DoesNotExist:
                provider = None

        # Link the chosen provider immediately so the tracking page can show
        # who the user requested, but keep status 'pending' until they accept.
        req = _sr_service.create_request(request.user, serializer.validated_data, provider=provider)

        if provider:
            from apps.notifications.services import notify_provider
            try:
                notify_provider(
                    provider,
                    'new_request',
                    'طلب خدمة جديد',
                    f'لديك طلب جديد من {request.user.full_name} - {req.service_type}',
                    related_request_id=req.service_request_id,
                )
            except Exception as e:
                import logging
                logging.getLogger(__name__).warning(
                    'notify_provider failed for provider_id=%s: %s', provider_id, e
                )

        return Response(ServiceRequestSerializer(req, context={'request': request}).data,
                        status=status.HTTP_201_CREATED)


@extend_schema(tags=['Service Requests'])
class ServiceRequestDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated, IsOwnerOrAssignedProvider]
    serializer_class = ServiceRequestSerializer
    queryset = ServiceRequest.objects.all()
    lookup_field = 'service_request_id'
    lookup_url_kwarg = 'pk'

    def get_object(self):
        _sr_service.expire_stale_pending_requests()
        obj = super().get_object()
        self.check_object_permissions(self.request, obj)
        return obj


@extend_schema(tags=['Service Requests'], request=None, responses={200: ServiceRequestSerializer})
class ServiceRequestCancelView(APIView):
    permission_classes = [IsAuthenticated, IsServiceUser]

    def patch(self, request, pk):
        req = self._get_request(pk)
        self.check_object_permissions(request, req)
        provider = req.service_provider
        _sr_service.cancel_request(req, request.user)
        req.refresh_from_db()
        # Notify the assigned provider (if any) about the cancellation
        if provider:
            from apps.notifications.services import notify_provider
            notify_provider(
                provider,
                'request_cancelled',
                'تم إلغاء الطلب',
                f'قام {request.user.full_name} بإلغاء طلب {req.service_type}',
                related_request_id=req.service_request_id,
            )
        return Response(ServiceRequestSerializer(req, context={'request': request}).data)

    def _get_request(self, pk):
        from django.shortcuts import get_object_or_404
        return get_object_or_404(ServiceRequest, pk=pk)


@extend_schema(tags=['Service Requests'], request=None, responses={200: ServiceRequestSerializer})
class ServiceRequestAssignView(APIView):
    permission_classes = [IsAuthenticated, IsServiceProvider]

    def post(self, request, pk):
        from django.shortcuts import get_object_or_404
        req = get_object_or_404(ServiceRequest, pk=pk)
        provider = request.user.provider
        _sr_service.assign_provider(req, provider)
        req.refresh_from_db()
        from apps.notifications.services import notify_user
        notify_user(
            req.user,
            'request_accepted',
            'تم قبول طلبك',
            f'تم تعيين {provider.full_name} لطلبك',
            related_request_id=req.service_request_id,
        )
        return Response(ServiceRequestSerializer(req, context={'request': request}).data)


@extend_schema(tags=['Service Requests'], request=None, responses={200: ServiceRequestSerializer})
class ServiceRequestDeclineView(APIView):
    permission_classes = [IsAuthenticated, IsServiceProvider]

    def post(self, request, pk):
        from django.shortcuts import get_object_or_404
        req = get_object_or_404(ServiceRequest, pk=pk)
        provider = request.user.provider
        _sr_service.decline_request(req, provider)
        req.refresh_from_db()
        from apps.notifications.services import notify_user
        notify_user(
            req.user,
            'request_declined',
            'تم رفض طلبك',
            f'رفض مزود الخدمة طلبك ({req.service_type}). سيتم وضعه في الانتظار.',
            related_request_id=req.service_request_id,
        )
        return Response(ServiceRequestSerializer(req, context={'request': request}).data)


@extend_schema(tags=['Service Requests'], request=ServiceRequestCreateSerializer,
               responses={200: ServiceRequestSerializer})
class ServiceRequestStatusUpdateView(APIView):
    permission_classes = [IsAuthenticated, IsServiceProvider]

    def patch(self, request, pk):
        from django.shortcuts import get_object_or_404
        req = get_object_or_404(ServiceRequest, pk=pk)
        new_status = request.data.get('status')
        if not new_status:
            return Response(
                {'detail': "'status' field is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        provider = request.user.provider
        _sr_service.update_status(req, new_status, provider)
        req.refresh_from_db()
        return Response(ServiceRequestSerializer(req, context={'request': request}).data)


@extend_schema(tags=['Service Requests'], responses={200: ServiceRequestStatusTrackingSerializer(many=True)})
class ServiceRequestTrackingView(APIView):
    permission_classes = [IsAuthenticated, IsOwnerOrAssignedProvider]

    def get(self, request, pk):
        from django.shortcuts import get_object_or_404
        req = get_object_or_404(ServiceRequest, pk=pk)
        self.check_object_permissions(request, req)
        history = req.status_history.all()
        return Response(ServiceRequestStatusTrackingSerializer(history, many=True).data)


# ── Services ──────────────────────────────────────────────────────────────────

@extend_schema(tags=['Services'])
class ServiceCreateView(generics.CreateAPIView):
    permission_classes = [IsAuthenticated, IsServiceProvider]
    serializer_class = ServiceCreateSerializer

    def perform_create(self, serializer):
        req = serializer.validated_data['service_request']
        if req.service_provider != self.request.user.provider:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied('Only the assigned Service Provider can create a Service record.')
        serializer.save(service_provider=self.request.user.provider)


@extend_schema(tags=['Services'])
class ServiceDetailView(generics.RetrieveAPIView):
    permission_classes = [IsAuthenticated, IsOwnerOrAssignedProvider]
    serializer_class = ServiceSerializer
    queryset = Service.objects.select_related('service_request')
    lookup_field = 'service_id'
    lookup_url_kwarg = 'pk'

    def get_object(self):
        obj = super().get_object()
        # Delegate ownership check to the parent service_request
        self.check_object_permissions(self.request, obj.service_request)
        return obj


# ── Saved Providers ───────────────────────────────────────────────────────────

@extend_schema(tags=['Service Requests'])
class SavedProviderListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated, IsServiceUser]
    serializer_class = SavedProviderSerializer

    def get_queryset(self):
        return SavedProvider.objects.filter(user=self.request.user).select_related('service_provider')


@extend_schema(tags=['Service Requests'], request=SavedProviderSerializer,
               responses={201: SavedProviderSerializer})
class SavedProviderCreateView(APIView):
    permission_classes = [IsAuthenticated, IsServiceUser]

    def post(self, request):
        provider_id = request.data.get('provider_id')
        if not provider_id:
            return Response(
                {'detail': "'provider_id' is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        from django.shortcuts import get_object_or_404
        provider = get_object_or_404(ServiceProvider, pk=provider_id)
        saved = _sp_service.save_provider(request.user, provider)
        return Response(SavedProviderSerializer(saved).data, status=status.HTTP_201_CREATED)


@extend_schema(tags=['Service Requests'], responses={204: None})
class SavedProviderDeleteView(APIView):
    permission_classes = [IsAuthenticated, IsServiceUser]

    def delete(self, request, provider_id):
        from django.shortcuts import get_object_or_404
        provider = get_object_or_404(ServiceProvider, pk=provider_id)
        _sp_service.unsave_provider(request.user, provider)
        return Response(status=status.HTTP_204_NO_CONTENT)
