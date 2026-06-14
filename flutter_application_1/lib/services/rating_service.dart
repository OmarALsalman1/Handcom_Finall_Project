import 'dart:convert';
import 'api_service.dart';
import '../core/config/api_config.dart';

class RatingService {
  static Future<({bool success, String? error, String? errorCode})> submitRating({
    required int serviceId,
    required int ratingValue,
    String? comment,
  }) async {
    try {
      final body = <String, dynamic>{
        'service_id': serviceId,
        'rating_value': ratingValue,
      };
      if (comment != null && comment.trim().isNotEmpty) {
        body['rating_comment'] = comment.trim();
      }

      final response = await ApiService.post(
        ApiConfig.ratings,
        body,
        authenticated: true,
      );
      if (response.statusCode == 201) {
        return (success: true, error: null, errorCode: null);
      }
      return (
        success: false,
        error: ApiService.extractError(response),
        errorCode: ApiService.extractErrorCode(response),
      );
    } on ApiException catch (e) {
      return (success: false, error: null, errorCode: e.code);
    } catch (e) {
      return (success: false, error: e.toString(), errorCode: 'server_error');
    }
  }

  static Future<Map<String, dynamic>?> getProviderRatings(int providerId) async {
    try {
      final response = await ApiService.get(
          '${ApiConfig.serviceProviders}$providerId/ratings/');
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {}
    return null;
  }
}
