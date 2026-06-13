import 'dart:convert';
import 'api_service.dart';
import '../core/config/api_config.dart';

class ServiceRequestModel {
  final int id;
  final String serviceType;
  final String location;
  final String description;
  final String status;
  final String? providerName;
  final String? userName;
  final String createdAt;
  final int? serviceProviderId;
  final int? serviceId;

  ServiceRequestModel({
    required this.id,
    required this.serviceType,
    required this.location,
    required this.description,
    required this.status,
    this.providerName,
    this.userName,
    required this.createdAt,
    this.serviceProviderId,
    this.serviceId,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    final provider = json['service_provider'];
    String? pName;
    int? pId;
    if (provider is Map) {
      pName = provider['full_name'] as String?;
      pId = provider['service_provider_id'] as int?;
    }
    return ServiceRequestModel(
      id: json['service_request_id'] ?? json['id'] ?? 0,
      serviceType: json['service_type'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      status: json['current_status'] ?? json['status'] ?? 'pending',
      providerName: pName,
      userName: json['user_name'] as String?,
      createdAt: json['created_at'] ?? '',
      serviceProviderId: pId,
      serviceId: json['service_id'] as int?,
    );
  }

  static const Map<String, String> _statusArabic = {
    'pending': 'قيد الانتظار',
    'on_hold': 'في الانتظار',
    'accepted': 'مقبول',
    'in_progress': 'جاري التنفيذ',
    'completed': 'مكتمل',
    'cancelled': 'ملغي',
  };

  static const Map<String, String> _statusEn = {
    'pending': 'Pending',
    'on_hold': 'On Hold',
    'accepted': 'Accepted',
    'in_progress': 'In Progress',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  static const Map<String, String> _typeArabic = {
    'plumbing': 'سباكة',
    'electrical': 'كهرباء',
    'painting': 'دهان',
    'carpentry': 'نجارة',
    'general': 'عام',
  };

  static const Map<String, String> _typeEn = {
    'plumbing': 'Plumbing',
    'electrical': 'Electrical',
    'painting': 'Painting',
    'carpentry': 'Carpentry',
    'general': 'General',
  };

  String get statusArabic => _statusArabic[status] ?? status;
  String get serviceTypeArabic => _typeArabic[serviceType] ?? serviceType;
  String statusLabel(bool isAr) => (isAr ? _statusArabic : _statusEn)[status] ?? status;
  String serviceTypeLabel(bool isAr) => (isAr ? _typeArabic : _typeEn)[serviceType] ?? serviceType;
}

class RequestService {
  static Future<List<ServiceRequestModel>> getMyRequests() async {
    try {
      final response = await ApiService.get(ApiConfig.serviceRequests);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> data =
            decoded is Map ? (decoded['results'] ?? []) : decoded as List;
        return data.map((e) => ServiceRequestModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<ServiceRequestModel>> getIncomingRequests() async {
    try {
      final response = await ApiService.get('${ApiConfig.serviceRequests}?incoming=true');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> data =
            decoded is Map ? (decoded['results'] ?? []) : decoded as List;
        return data.map((e) => ServiceRequestModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<({ServiceRequestModel? model, String? error})> createRequest({
    required String serviceType,
    required String location,
    required String description,
    int? providerId,
    String? scheduledFor,
  }) async {
    try {
      final body = <String, dynamic>{
        'service_type': serviceType,
        'location': location,
        'description': description,
      };
      if (providerId != null) body['provider_id'] = providerId;
      if (scheduledFor != null) body['scheduled_for'] = scheduledFor;

      final response = await ApiService.post(
        ApiConfig.serviceRequests,
        body,
        authenticated: true,
      );
      if (response.statusCode == 201) {
        return (
          model: ServiceRequestModel.fromJson(
              jsonDecode(utf8.decode(response.bodyBytes))),
          error: null,
        );
      }
      return (model: null, error: '[${response.statusCode}] ${ApiService.extractError(response)}');
    } catch (e) {
      return (model: null, error: e.toString());
    }
  }

  static Future<bool> assignProvider(int requestId) async {
    try {
      final response = await ApiService.post(
        '${ApiConfig.serviceRequests}$requestId/assign/',
        {},
        authenticated: true,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> declineRequest(int requestId) async {
    try {
      final response = await ApiService.post(
        '${ApiConfig.serviceRequests}$requestId/decline/',
        {},
        authenticated: true,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancelRequest(int requestId) async {
    try {
      final response = await ApiService.patch(
        '${ApiConfig.serviceRequests}$requestId/cancel/',
        {},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateStatus(int requestId, String status) async {
    try {
      final response = await ApiService.patch(
        '${ApiConfig.serviceRequests}$requestId/status/',
        {'status': status},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<ServiceRequestModel?> getById(int requestId) async {
    try {
      final response =
          await ApiService.get('${ApiConfig.serviceRequests}$requestId/');
      if (response.statusCode == 200) {
        return ServiceRequestModel.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (_) {}
    return null;
  }
}
