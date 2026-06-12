from datetime import timedelta

from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import PermissionDenied
from drf_spectacular.utils import extend_schema

from apps.accounts.models import ServiceProvider
from apps.accounts.permissions import IsServiceProvider

from .models import ServiceProviderSchedule
from .serializers import ScheduleSerializer, ScheduleWriteSerializer
from .services import ScheduleService

_sched_service = ScheduleService()


# ── Create / My List ──────────────────────────────────────────────────────────

@extend_schema(tags=['Schedules'], request=ScheduleWriteSerializer, responses={201: ScheduleSerializer})
class ScheduleCreateView(APIView):
    permission_classes = [IsAuthenticated, IsServiceProvider]

    def post(self, request):
        serializer = ScheduleWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data
        slot = _sched_service.create_slot(
            provider=request.user.provider,
            working_date=d['working_date'],
            start_time=d['start_time'],
            end_time=d['end_time'],
        )
        return Response(ScheduleSerializer(slot).data, status=status.HTTP_201_CREATED)


@extend_schema(tags=['Schedules'], responses={200: ScheduleSerializer(many=True)})
class MyScheduleListView(APIView):
    permission_classes = [IsAuthenticated, IsServiceProvider]

    def get(self, request):
        slots = ServiceProviderSchedule.objects.filter(
            service_provider=request.user.provider
        )
        return Response(ScheduleSerializer(slots, many=True).data)


# ── Update / Delete (owner only) ──────────────────────────────────────────────

@extend_schema(tags=['Schedules'], request=ScheduleWriteSerializer,
               responses={200: ScheduleSerializer, 204: None})
class ScheduleDetailView(APIView):
    permission_classes = [IsAuthenticated, IsServiceProvider]

    def _get_owned_slot(self, request, pk):
        slot = get_object_or_404(ServiceProviderSchedule, pk=pk)
        if slot.service_provider != request.user.provider:
            raise PermissionDenied('You can only modify your own schedule slots.')
        return slot

    def put(self, request, pk):
        slot = self._get_owned_slot(request, pk)
        serializer = ScheduleWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        d = serializer.validated_data
        updated = _sched_service.update_slot(
            slot=slot,
            working_date=d['working_date'],
            start_time=d['start_time'],
            end_time=d['end_time'],
        )
        return Response(ScheduleSerializer(updated).data)

    def delete(self, request, pk):
        slot = self._get_owned_slot(request, pk)
        slot.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


# ── Public view: provider's schedule for the next 14 days ────────────────────

@extend_schema(tags=['Schedules'], request=None, responses={200: ScheduleSerializer(many=True)})
class ServiceProviderPublicScheduleView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        provider = get_object_or_404(ServiceProvider, pk=pk)
        today = timezone.now().date()
        cutoff = today + timedelta(days=14)
        slots = ServiceProviderSchedule.objects.filter(
            service_provider=provider,
            working_date__gte=today,
            working_date__lte=cutoff,
        )
        return Response(ScheduleSerializer(slots, many=True).data)
