from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views

urlpatterns = [
    # ── Auth: Service User ────────────────────────────────────────────────────
    path('auth/service-user/register/', views.UserRegisterView.as_view(), name='user-register'),
    path('auth/service-user/login/', views.UserLoginView.as_view(), name='user-login'),

    # ── Auth: Service Provider ────────────────────────────────────────────────
    path('auth/service-provider/register/', views.ServiceProviderRegisterView.as_view(), name='provider-register'),
    path('auth/service-provider/login/', views.ServiceProviderLoginView.as_view(), name='provider-login'),

    # ── Token refresh (shared) ────────────────────────────────────────────────
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),

    # ── Email verification ────────────────────────────────────────────────────
    path('auth/verify-email/', views.VerifyEmailView.as_view(), name='verify-email'),
    path('auth/resend-otp/', views.ResendVerificationOTPView.as_view(), name='resend-otp'),

    # ── Password reset ────────────────────────────────────────────────────────
    path('auth/password-reset/request/', views.PasswordResetRequestView.as_view(), name='password-reset-request'),
    path('auth/password-reset/confirm/', views.PasswordResetConfirmView.as_view(), name='password-reset-confirm'),

    # ── Service User profile ──────────────────────────────────────────────────
    path('users/me/', views.UserMeView.as_view(), name='user-me'),

    # ── Service Provider endpoints ────────────────────────────────────────────
    path('service-providers/me/availability/', views.ServiceProviderAvailabilityView.as_view(), name='provider-availability'),
    path('service-providers/me/', views.ServiceProviderMeView.as_view(), name='provider-me'),
    path('service-providers/<int:pk>/', views.ServiceProviderDetailView.as_view(), name='provider-detail'),
    path('service-providers/', views.ServiceProviderListView.as_view(), name='provider-list'),
]
