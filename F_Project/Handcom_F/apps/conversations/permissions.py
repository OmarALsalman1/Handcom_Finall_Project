from rest_framework.permissions import BasePermission


class IsConversationParticipant(BasePermission):
    """
    Object-level permission: grants access only to the conversation's user
    or its assigned service provider.
    """
    message = 'You are not a participant in this conversation.'

    def has_object_permission(self, request, view, obj):
        token = request.auth
        if token is None:
            return False
        role = token.get('role')
        if role == 'service_user':
            return obj.user == request.user
        if role == 'service_provider':
            provider = getattr(request.user, 'provider', None)
            return provider is not None and obj.service_provider == provider
        return False
