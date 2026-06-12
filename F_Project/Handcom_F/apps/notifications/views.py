from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Notification
from .serializers import NotificationSerializer


def _get_qs(request):
    token = request.auth
    role = token.get('role') if token else None
    if role == 'service_provider':
        return Notification.objects.filter(recipient_provider=request.user.provider)
    return Notification.objects.filter(recipient_user=request.user)


class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        qs = _get_qs(request)
        return Response(NotificationSerializer(qs, many=True).data)


class NotificationMarkReadView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        qs = _get_qs(request)
        try:
            notif = qs.get(pk=pk)
        except Notification.DoesNotExist:
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        notif.is_read = True
        notif.save(update_fields=['is_read'])
        return Response(NotificationSerializer(notif).data)


class NotificationMarkAllReadView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request):
        _get_qs(request).update(is_read=True)
        return Response({'detail': 'All marked as read.'})


class NotificationUnreadCountView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        count = _get_qs(request).filter(is_read=False).count()
        return Response({'unread_count': count})

