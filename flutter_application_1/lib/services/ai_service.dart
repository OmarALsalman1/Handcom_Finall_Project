import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../core/config/api_config.dart';

class AiProviderSuggestion {
  final int id;
  final String name;
  final String phone;
  final int experienceYears;
  final String availabilityStatus;
  final List<String> serviceCategories;
  final double? averageRating;
  final int totalRatings;

  AiProviderSuggestion({
    required this.id,
    required this.name,
    required this.phone,
    required this.experienceYears,
    required this.availabilityStatus,
    required this.serviceCategories,
    this.averageRating,
    required this.totalRatings,
  });

  factory AiProviderSuggestion.fromJson(Map<String, dynamic> json) {
    return AiProviderSuggestion(
      id: json['service_provider_id'] ?? 0,
      name: json['full_name'] ?? '',
      phone: json['phone'] ?? '',
      experienceYears: json['experience_years'] ?? 0,
      availabilityStatus: json['availability_status'] ?? 'offline',
      serviceCategories:
          List<String>.from(json['service_categories'] ?? []),
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
      totalRatings: json['total_ratings'] ?? 0,
    );
  }

  String get initial => name.isNotEmpty ? name.substring(0, 1) : '؟';
  String get statusArabic =>
      availabilityStatus == 'available' ? 'متاح' : 'مشغول';
  String get ratingDisplay =>
      averageRating != null ? averageRating!.toStringAsFixed(1) : '—';

  static const Map<String, String> _catArabic = {
    'plumbing': 'سباكة',
    'electrical': 'كهرباء',
    'painting': 'دهان',
    'carpentry': 'نجارة',
  };

  String get categoriesArabic =>
      serviceCategories.map((c) => _catArabic[c] ?? c).join(' ، ');

  static const Map<String, String> _catEnglish = {
    'plumbing': 'Plumbing',
    'electrical': 'Electrical',
    'painting': 'Painting',
    'carpentry': 'Carpentry',
  };

  String categoriesLabel(bool isAr) => isAr
      ? categoriesArabic
      : serviceCategories.map((c) => _catEnglish[c] ?? c).join(', ');
}

class AiChatResponse {
  final bool success;
  final int? conversationId;
  final String? aiMessage;
  final bool needsProvider;
  final String? serviceCategory;
  final List<AiProviderSuggestion> providers;
  final String? error;
  final String? errorCode;

  AiChatResponse({
    required this.success,
    this.conversationId,
    this.aiMessage,
    this.needsProvider = false,
    this.serviceCategory,
    this.providers = const [],
    this.error,
    this.errorCode,
  });
}

class AiService {
  static Future<AiChatResponse> sendMessage({
    String? text,
    File? image,
    File? voice,
    int? conversationId,
    String lang = 'ar',
  }) async {
    try {
      final fields = <String, String>{};
      if (text != null && text.trim().isNotEmpty) {
        fields['text'] = text.trim();
      }
      if (conversationId != null) {
        fields['conversation_id'] = conversationId.toString();
      }
      fields['lang'] = lang;

      final files = <http.MultipartFile>[];
      if (image != null) {
        files.add(await http.MultipartFile.fromPath('image', image.path));
      }
      if (voice != null) {
        files.add(await http.MultipartFile.fromPath('voice', voice.path));
      }

      final response =
          await ApiService.postMultipart(ApiConfig.aiChat, fields, files);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final rawProviders = (data['recommendations'] as List? ?? []);
        return AiChatResponse(
          success: true,
          conversationId: data['conversation_id'],
          aiMessage: data['ai_message']?.toString(),
          needsProvider: data['needs_provider'] == true,
          serviceCategory: data['service_category']?.toString(),
          providers: rawProviders
              .map((e) =>
                  AiProviderSuggestion.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
      return AiChatResponse(
        success: false,
        error: ApiService.extractError(response),
        errorCode: ApiService.extractErrorCode(response),
      );
    } on ApiException catch (e) {
      return AiChatResponse(success: false, errorCode: e.code);
    } catch (e) {
      return AiChatResponse(
          success: false, error: e.toString(), errorCode: 'server_error');
    }
  }

  static Future<({bool success, String? error, String? errorCode})>
      createRequestFromChat({
    required int conversationId,
    required String location,
    int? providerId,
  }) async {
    try {
      final body = <String, dynamic>{
        'ai_conversation_id': conversationId,
        'location': location,
      };
      if (providerId != null) body['service_provider_id'] = providerId;

      final response = await ApiService.post(
          ApiConfig.aiCreateRequest, body,
          authenticated: true);
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
}
