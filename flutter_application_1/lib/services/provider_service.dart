import 'dart:convert';
import 'api_service.dart';
import '../core/config/api_config.dart';

class ProviderModel {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final List<String> serviceCategories;
  final String availabilityStatus;
  final int experienceYears;
  final double? averageRating;
  final int totalRatings;
  final double? latitude;
  final double? longitude;

  ProviderModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.serviceCategories,
    required this.availabilityStatus,
    required this.experienceYears,
    this.averageRating,
    required this.totalRatings,
    this.latitude,
    this.longitude,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['service_provider_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      serviceCategories: List<String>.from(json['service_categories'] ?? []),
      availabilityStatus: json['availability_status'] ?? 'offline',
      experienceYears: json['experience_years'] ?? 0,
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
      totalRatings: json['total_ratings'] ?? 0,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }

  // Arabic status label
  String get statusArabic =>
      availabilityStatus == 'available' ? 'متاح' : 'غير متاح';

  // First letter for avatar placeholder
  String get initial =>
      fullName.isNotEmpty ? fullName.substring(0, 1) : '؟';

  String get ratingDisplay =>
      averageRating != null ? averageRating!.toStringAsFixed(1) : '0.0';
}

class ProviderService {
  static const Map<String, String> _categoryArabicToEnglish = {
    'سباكة': 'plumbing',
    'كهرباء': 'electrical',
    'دهان': 'painting',
    'نجارة': 'carpentry',
  };

  static Future<List<ProviderModel>> getProviders({
    String? category,
    double? userLat,
    double? userLng,
  }) async {
    try {
      String url = ApiConfig.serviceProviders;
      final params = <String>[];
      if (category != null) {
        final eng = _categoryArabicToEnglish[category] ?? category;
        params.add('category=$eng');
      }
      if (userLat != null && userLng != null) {
        params.add('lat=$userLat&lng=$userLng');
      }
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> data =
            decoded is Map ? (decoded['results'] ?? []) : decoded as List;
        return data.map((e) => ProviderModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<ProviderModel?> getProviderById(int id) async {
    try {
      final response =
          await ApiService.get('${ApiConfig.serviceProviders}$id/');
      if (response.statusCode == 200) {
        return ProviderModel.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (_) {}
    return null;
  }
}
