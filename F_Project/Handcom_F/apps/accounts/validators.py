import re
from django.core.exceptions import ValidationError

VALID_SERVICE_CATEGORIES = frozenset([
    'plumbing', 'electrical', 'painting', 'carpentry',
])


def validate_password_strength(password: str) -> None:
    if len(password) < 6:
        raise ValidationError('Password must be at least 6 characters.')
    if not any(c.isdigit() for c in password):
        raise ValidationError('Password must contain at least one digit.')
    if not any(c.isalpha() for c in password):
        raise ValidationError('Password must contain at least one letter.')


def validate_phone(phone: str) -> None:
    if not re.match(r'^\+?\d{7,15}$', phone):
        raise ValidationError('Phone must be 7–15 digits, optionally prefixed with +.')
