from rest_framework.permissions import BasePermission


class IsServiceUser(BasePermission):
    """Grants access only to authenticated Service Users (role='service_user' JWT claim)."""
    message = 'This endpoint requires a Service User account.'

    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        token = request.auth
        return token is not None and token.get('role') == 'service_user'


class IsServiceProvider(BasePermission):
    """Grants access only to authenticated Service Providers (role='service_provider' JWT claim)."""
    message = 'This endpoint requires a Service Provider account.'

    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated):
            return False
        token = request.auth
        return token is not None and token.get('role') == 'service_provider'


class IsOwnerOrAssignedProvider(BasePermission):
    """
    Object-level permission.
    - Service User: passes if obj.user == request.user
    - Service Provider: passes if obj.service_provider == request.user.provider
    """
    message = 'You do not have permission to access this resource.'

    def has_object_permission(self, request, view, obj):
        token = request.auth
        if token is None:
            return False
        role = token.get('role')
        if role == 'service_user':
            return getattr(obj, 'user', None) == request.user
        if role == 'service_provider':
            provider = getattr(request.user, 'provider', None)
            return provider is not None and getattr(obj, 'service_provider', None) == provider
        return False
