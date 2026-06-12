import 'dart:convert';
import 'api_service.dart';
import '../core/config/api_config.dart';

class RatingService {
  static Future<bool> submitRating({
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
      return response.statusCode == 201;
    } catch (_) {
      return false;
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
