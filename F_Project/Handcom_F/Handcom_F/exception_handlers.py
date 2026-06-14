import logging

from rest_framework.exceptions import ErrorDetail
from rest_framework.response import Response
from rest_framework.views import exception_handler as drf_exception_handler

logger = logging.getLogger(__name__)


def _find_code(data):
    """Recursively find the first non-default ErrorDetail.code in a DRF error payload."""
    if isinstance(data, ErrorDetail):
        return None if data.code in (None, 'error', 'invalid') else data.code
    if isinstance(data, (list, tuple)):
        for item in data:
            code = _find_code(item)
            if code:
                return code
    if isinstance(data, dict):
        for value in data.values():
            code = _find_code(value)
            if code:
                return code
    return None


def custom_exception_handler(exc, context):
    """Wraps DRF's default handler to guarantee a stable `code` field on every
    error response, and to turn unhandled exceptions into a logged JSON 500
    instead of an HTML debug page.
    """
    response = drf_exception_handler(exc, context)

    if response is None:
        logger.exception('Unhandled exception in %s', context.get('view'))
        return Response(
            {
                'detail': 'An unexpected error occurred. Please try again later.',
                'code': 'server_error',
            },
            status=500,
        )

    if isinstance(response.data, dict) and 'code' not in response.data:
        response.data['code'] = _find_code(response.data) or getattr(exc, 'default_code', 'error')

    return response
