from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken


class ServiceProviderPrincipal:
    """Wraps ServiceProvider so DRF treats it as an authenticated principal."""
    is_anonymous = False
    is_authenticated = True

    def __init__(self, provider):
        self.provider = provider

    def __str__(self):
        return f"ServiceProvider:{self.provider.email}"


class HandcomJWTAuthentication(JWTAuthentication):
    """
    Extends JWTAuthentication to support both Service Users (Django User)
    and Service Providers (separate model, manual JWT).

    Token routing:
      - role='service_provider' → look up ServiceProvider by provider_id claim
      - anything else           → standard Django user lookup via user_id
    """

    def get_user(self, validated_token):
        role = validated_token.get('role')
        if role == 'service_provider':
            from apps.accounts.models import ServiceProvider
            provider_id = validated_token.get('provider_id')
            if not provider_id:
                raise InvalidToken('Token is missing the provider_id claim.')
            try:
                provider = ServiceProvider.objects.get(service_provider_id=provider_id)
            except ServiceProvider.DoesNotExist:
                raise InvalidToken('Service provider not found.')
            return ServiceProviderPrincipal(provider)
        return super().get_user(validated_token)


# ── drf-spectacular auth extension ───────────────────────────────────────────

try:
    from drf_spectacular.extensions import OpenApiAuthenticationExtension

    class HandcomJWTScheme(OpenApiAuthenticationExtension):
        target_class = 'apps.accounts.authentication.HandcomJWTAuthentication'
        name = 'HandcomJWTAuth'

        def get_security_definition(self, auto_schema):
            return {
                'type': 'http',
                'scheme': 'bearer',
                'bearerFormat': 'JWT',
                'description': (
                    'JWT Bearer token. Service Users get tokens from '
                    '`/api/v1/auth/service-user/login/`; '
                    'Service Providers from `/api/v1/auth/service-provider/login/`.'
                ),
            }
except ImportError:
    pass
