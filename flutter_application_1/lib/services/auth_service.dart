import 'dart:convert';
import 'api_service.dart';
import '../core/config/api_config.dart';

class AuthResult {
  final bool success;
  final String? error;
  final String? errorCode;
  final String? role;

  AuthResult({required this.success, this.error, this.errorCode, this.role});
}

class AuthService {
  // ─── Service User Login ───────────────────────────────────────────────────

  static Future<AuthResult> loginUser(String email, String password) async {
    try {
      final response = await ApiService.post(ApiConfig.loginUser, {
        'email': email.trim(),
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiService.saveTokens(
          access: data['access'],
          refresh: data['refresh'],
          role: data['role'] ?? 'service_user',
          email: data['email'],
          userId: data['user_id'],
        );
        return AuthResult(success: true, role: 'service_user');
      }
      return AuthResult(
        success: false,
        error: ApiService.extractError(response),
        errorCode: ApiService.extractErrorCode(response),
      );
    } on ApiException catch (e) {
      return AuthResult(success: false, errorCode: e.code);
    } catch (_) {
      return AuthResult(success: false, errorCode: 'server_error');
    }
  }

  // ─── Service User Register ────────────────────────────────────────────────

  static Future<AuthResult> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.registerUser, {
        'full_name': '${firstName.trim()} ${lastName.trim()}',
        'email': email.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'password': password,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthResult(success: true);
      }
      return AuthResult(
        success: false,
        error: ApiService.extractError(response),
        errorCode: ApiService.extractErrorCode(response),
      );
    } on ApiException catch (e) {
      return AuthResult(success: false, errorCode: e.code);
    } catch (_) {
      return AuthResult(success: false, errorCode: 'server_error');
    }
  }

  // ─── Service Provider Login ───────────────────────────────────────────────

  static Future<AuthResult> loginProvider(String email, String password) async {
    try {
      final response = await ApiService.post(ApiConfig.loginProvider, {
        'email': email.trim(),
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiService.saveTokens(
          access: data['access'],
          refresh: data['refresh'],
          role: data['role'] ?? 'service_provider',
          email: data['email'],
          providerId: data['provider_id'],
        );
        return AuthResult(success: true, role: 'service_provider');
      }
      return AuthResult(
        success: false,
        error: ApiService.extractError(response),
        errorCode: ApiService.extractErrorCode(response),
      );
    } on ApiException catch (e) {
      return AuthResult(success: false, errorCode: e.code);
    } catch (_) {
      return AuthResult(success: false, errorCode: 'server_error');
    }
  }

  // ─── Service Provider Register ────────────────────────────────────────────

  static const Map<String, String> _categoryMap = {
    'سباكة': 'plumbing',
    'كهرباء': 'electrical',
    'دهان': 'painting',
    'نجارة': 'carpentry',
    'Plumbing': 'plumbing',
    'Electrical': 'electrical',
    'Painting': 'painting',
    'Carpentry': 'carpentry',
  };

  static Future<AuthResult> registerProvider({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required List<String> selectedJobs,
    required String password,
  }) async {
    final categories = selectedJobs
        .map((j) => _categoryMap[j])
        .where((c) => c != null)
        .cast<String>()
        .toList();

    try {
      final response = await ApiService.post(ApiConfig.registerProvider, {
        'full_name': '${firstName.trim()} ${lastName.trim()}',
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'experience_years': 0,
        'service_categories': categories,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthResult(success: true);
      }
      return AuthResult(
        success: false,
        error: ApiService.extractError(response),
        errorCode: ApiService.extractErrorCode(response),
      );
    } on ApiException catch (e) {
      return AuthResult(success: false, errorCode: e.code);
    } catch (_) {
      return AuthResult(success: false, errorCode: 'server_error');
    }
  }

  // ─── Email Verification ───────────────────────────────────────────────────

  static Future<AuthResult> verifyEmail({
    required String email,
    required String otp,
    required String role,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.verifyEmail, {
        'email': email.trim(),
        'otp': otp.trim(),
        'role': role,
      });
      if (response.statusCode == 200) {
        return AuthResult(success: true);
      }
      return AuthResult(
        success: false,
        error: ApiService.extractError(response),
        errorCode: ApiService.extractErrorCode(response),
      );
    } on ApiException catch (e) {
      return AuthResult(success: false, errorCode: e.code);
    } catch (_) {
      return AuthResult(success: false, errorCode: 'server_error');
    }
  }

  static Future<AuthResult> resendVerificationOtp({
    required String email,
    required String role,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.resendOtp, {
        'email': email.trim(),
        'role': role,
      });
      if (response.statusCode == 200) {
        return AuthResult(success: true);
      }
      return AuthResult(
        success: false,
        error: ApiService.extractError(response),
        errorCode: ApiService.extractErrorCode(response),
      );
    } on ApiException catch (e) {
      return AuthResult(success: false, errorCode: e.code);
    } catch (_) {
      return AuthResult(success: false, errorCode: 'server_error');
    }
  }

  // ─── Password Reset ───────────────────────────────────────────────────────

  static Future<AuthResult> requestPasswordReset(String email) async {
    try {
      final response = await ApiService.post(ApiConfig.passwordResetRequest, {
        'email': email.trim(),
      });

      if (response.statusCode == 200) {
        return AuthResult(success: true);
      }
      return AuthResult(
        success: false,
        error: ApiService.extractError(response),
        errorCode: ApiService.extractErrorCode(response),
      );
    } on ApiException catch (e) {
      return AuthResult(success: false, errorCode: e.code);
    } catch (_) {
      return AuthResult(success: false, errorCode: 'server_error');
    }
  }

  static Future<AuthResult> confirmPasswordReset({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.passwordResetConfirm, {
        'email': email.trim(),
        'otp': otp.trim(),
        'new_password': newPassword,
      });

      if (response.statusCode == 200) {
        return AuthResult(success: true);
      }
      return AuthResult(
        success: false,
        error: ApiService.extractError(response),
        errorCode: ApiService.extractErrorCode(response),
      );
    } on ApiException catch (e) {
      return AuthResult(success: false, errorCode: e.code);
    } catch (_) {
      return AuthResult(success: false, errorCode: 'server_error');
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  static Future<void> logout() => ApiService.clearTokens();
}
