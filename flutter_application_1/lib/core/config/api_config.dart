class ApiConfig {
  // Override at build/run time with:
  //   flutter run --dart-define=API_BASE_URL=http://<host>:8000/api/v1
  // Defaults to the Android emulator's loopback alias for the host machine.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const String loginUser = '$baseUrl/auth/service-user/login/';
  static const String registerUser = '$baseUrl/auth/service-user/register/';
  static const String loginProvider = '$baseUrl/auth/service-provider/login/';
  static const String registerProvider = '$baseUrl/auth/service-provider/register/';
  static const String tokenRefresh = '$baseUrl/auth/token/refresh/';
  static const String verifyEmail = '$baseUrl/auth/verify-email/';
  static const String resendOtp = '$baseUrl/auth/resend-otp/';
  static const String passwordResetRequest = '$baseUrl/auth/password-reset/request/';
  static const String passwordResetConfirm = '$baseUrl/auth/password-reset/confirm/';

  static const String serviceProviders = '$baseUrl/service-providers/';
  static const String serviceRequests = '$baseUrl/service-requests/';
  static const String conversations = '$baseUrl/conversations/';
  static const String ratings = '$baseUrl/ratings/';
  static const String aiChat = '$baseUrl/ai/chat/';
  static const String aiConversations = '$baseUrl/ai/conversations/';
  static const String aiCreateRequest = '$baseUrl/ai/create-request/';
  static const String notifications = '$baseUrl/notifications/';
  static const String notificationsReadAll = '$baseUrl/notifications/read-all/';
  static const String notificationsUnreadCount = '$baseUrl/notifications/unread-count/';
  static const String savedProviders = '$baseUrl/saved-providers/';
  static const String savedProvidersAdd = '$baseUrl/saved-providers/add/';
  static const String userMe = '$baseUrl/users/me/';
  static const String providerMe = '$baseUrl/service-providers/me/';
  static const String providerAvailability = '$baseUrl/service-providers/me/availability/';
}
