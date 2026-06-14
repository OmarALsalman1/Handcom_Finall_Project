import random
import string
from django.utils import timezone
from datetime import timedelta
from django.core.mail import send_mail
from django.conf import settings
from rest_framework.exceptions import APIException
from .models import PasswordResetOTP


class EmailDeliveryError(APIException):
    status_code = 503
    default_detail = 'Could not send the verification email. Please try again later.'
    default_code = 'email_send_failed'


class OTPService:
    TTL_SECONDS = 300

    def send(self, email: str, role: str, purpose: str = 'reset') -> str:
        code = ''.join(random.choices(string.digits, k=6))
        expires_at = timezone.now() + timedelta(seconds=self.TTL_SECONDS)
        # Invalidate any previous unused OTPs for this email + role
        PasswordResetOTP.objects.filter(
            email=email, role=role, is_used=False
        ).update(is_used=True)
        PasswordResetOTP.objects.create(
            email=email, role=role, code=code, expires_at=expires_at
        )
        self._send_email(email, code, purpose)
        return code

    def verify(self, email: str, role: str, code: str) -> str:
        """Returns 'ok', 'expired', or 'invalid'."""
        try:
            otp = PasswordResetOTP.objects.get(
                email=email, role=role, code=code, is_used=False,
            )
        except PasswordResetOTP.DoesNotExist:
            return 'invalid'
        if otp.expires_at <= timezone.now():
            return 'expired'
        otp.is_used = True
        otp.save(update_fields=['is_used'])
        return 'ok'

    @staticmethod
    def _send_email(email: str, code: str, purpose: str) -> None:
        if purpose == 'verification':
            subject = 'رمز تفعيل حساب Handcom'
            body = (
                f'مرحباً!\n\n'
                f'شكراً لتسجيلك في Handcom.\n\n'
                f'رمز التحقق لتفعيل حسابك:\n\n'
                f'    {code}\n\n'
                f'الرمز صالح لمدة 5 دقائق.\n'
                f'لا تشارك هذا الرمز مع أي شخص.\n\n'
                f'إذا لم تقم بالتسجيل في Handcom، يرجى تجاهل هذا البريد.\n\n'
                f'فريق Handcom'
            )
        else:
            subject = 'رمز إعادة تعيين كلمة المرور - Handcom'
            body = (
                f'مرحباً!\n\n'
                f'رمز إعادة تعيين كلمة المرور الخاص بك:\n\n'
                f'    {code}\n\n'
                f'الرمز صالح لمدة 5 دقائق.\n'
                f'لا تشارك هذا الرمز مع أي شخص.\n\n'
                f'إذا لم تطلب إعادة تعيين كلمة المرور، يرجى تجاهل هذا البريد.\n\n'
                f'فريق Handcom'
            )

        from_email = getattr(settings, 'DEFAULT_FROM_EMAIL', '')
        if not from_email or not getattr(settings, 'EMAIL_HOST_USER', ''):
            # Email not configured — print to console as fallback
            print(f'\n[OTP] To: {email} | Purpose: {purpose} | Code: {code}\n')
            return

        try:
            send_mail(
                subject=subject,
                message=body,
                from_email=from_email,
                recipient_list=[email],
                fail_silently=False,
            )
        except Exception as exc:
            print(f'[EMAIL ERROR] Failed to send to {email}: {exc}')
            print(f'[OTP FALLBACK] Code: {code}')
            raise EmailDeliveryError()
