import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart';

class ApiService {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _roleKey = 'user_role';
  static const _userIdKey = 'user_id';
  static const _providerIdKey = 'provider_id';
  static const _emailKey = 'user_email';

  // ─── Token storage ────────────────────────────────────────────────────────

  static Future<void> saveTokens({
    required String access,
    required String refresh,
    required String role,
    String? email,
    int? userId,
    int? providerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
    await prefs.setString(_roleKey, role);
    if (email != null) await prefs.setString(_emailKey, email);
    if (userId != null) await prefs.setInt(_userIdKey, userId);
    if (providerId != null) await prefs.setInt(_providerIdKey, providerId);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static Future<int?> getProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_providerIdKey);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_providerIdKey);
  }

  // ─── Auth headers ─────────────────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    String? token = await getAccessToken();
    if (token == null) return {'Content-Type': 'application/json'};

    // Try to refresh if token looks expired (simple check: attempt request)
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> _refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.tokenRefresh),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessKey, data['access']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ─── HTTP helpers (auto-retry on 401) ────────────────────────────────────

  static Future<http.Response> get(String url) async {
    var headers = await _authHeaders();
    var response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 401) {
      if (await _refreshAccessToken()) {
        headers = await _authHeaders();
        response = await http.get(Uri.parse(url), headers: headers);
      }
    }
    return response;
  }

  static Future<http.Response> post(String url, Map<String, dynamic> body,
      {bool authenticated = false}) async {
    Map<String, String> headers = authenticated
        ? await _authHeaders()
        : {'Content-Type': 'application/json'};

    var response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 401 && authenticated) {
      if (await _refreshAccessToken()) {
        headers = await _authHeaders();
        response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        );
      }
    }
    return response;
  }

  static Future<http.Response> patch(String url, Map<String, dynamic> body) async {
    var headers = await _authHeaders();
    var response = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 401) {
      if (await _refreshAccessToken()) {
        headers = await _authHeaders();
        response = await http.patch(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        );
      }
    }
    return response;
  }

  static Future<http.Response> delete(String url) async {
    var headers = await _authHeaders();
    var response = await http.delete(Uri.parse(url), headers: headers);
    if (response.statusCode == 401) {
      if (await _refreshAccessToken()) {
        headers = await _authHeaders();
        response = await http.delete(Uri.parse(url), headers: headers);
      }
    }
    return response;
  }

  // ─── Multipart POST (for files) ───────────────────────────────────────────

  static Future<http.Response> postMultipart(
    String url,
    Map<String, String> fields,
    List<http.MultipartFile> files,
  ) async {
    final token = await getAccessToken();
    final request = http.MultipartRequest('POST', Uri.parse(url));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields.addAll(fields);
    request.files.addAll(files);
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // ─── Error extraction ─────────────────────────────────────────────────────

  static String extractError(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map) {
        // Collect all error messages
        final messages = <String>[];
        data.forEach((key, value) {
          if (value is List) {
            messages.addAll(value.map((e) => e.toString()));
          } else if (value is String) {
            messages.add(value);
          }
        });
        if (messages.isNotEmpty) return messages.join('\n');
      }
    } catch (_) {}
    return 'حدث خطأ. الرجاء المحاولة مجدداً';
  }
}
