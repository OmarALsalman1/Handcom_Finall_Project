import 'dart:convert';
import 'api_service.dart';
import '../core/config/api_config.dart';

class MessageModel {
  final int id;
  final String content;
  final bool isSentByMe;
  final String sentAt;

  MessageModel({
    required this.id,
    required this.content,
    required this.isSentByMe,
    required this.sentAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, int myUserId) {
    final senderType = json['sender_type'] ?? '';
    final myRole = myUserId == -1 ? 'service_provider' : 'user';
    return MessageModel(
      id: json['message_id'] ?? 0,
      content: json['content'] ?? '',
      isSentByMe: senderType == myRole,
      sentAt: json['sent_at'] ?? '',
    );
  }
}

class ConversationModel {
  final int id;
  final int serviceRequestId;
  final bool isClosed;
  final String userName;
  final String providerName;
  final String startedAt;

  ConversationModel({
    required this.id,
    required this.serviceRequestId,
    required this.isClosed,
    required this.userName,
    required this.providerName,
    required this.startedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final sr = json['service_request'];
    int srId = 0;
    if (sr is Map) srId = sr['id'] ?? 0;
    if (sr is int) srId = sr;
    return ConversationModel(
      id: json['conversation_id'] ?? 0,
      serviceRequestId: srId,
      isClosed: json['conversation_status'] == 'closed',
      userName: json['user_name'] ?? '',
      providerName: json['provider_name'] ?? '',
      startedAt: json['started_at'] ?? '',
    );
  }
}

class ChatService {
  static Future<List<ConversationModel>> getMyConversations() async {
    try {
      final response = await ApiService.get(ApiConfig.conversations);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> data =
            decoded is Map ? (decoded['results'] ?? []) : decoded as List;
        return data.map((e) => ConversationModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Start or resume a direct conversation with a provider (no order needed).
  static Future<ConversationModel?> startDirectChat(int providerId) async {
    try {
      final response = await ApiService.post(
        ApiConfig.conversations,
        {'provider_id': providerId},
        authenticated: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ConversationModel.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (_) {}
    return null;
  }

  static Future<ConversationModel?> getOrCreateConversation(
      int serviceRequestId) async {
    try {
      final response = await ApiService.post(
        ApiConfig.conversations,
        {'service_request_id': serviceRequestId},
        authenticated: true,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ConversationModel.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)));
      }
    } catch (_) {}
    return null;
  }

  static Future<List<MessageModel>> getMessages(
      int conversationId, String myRole) async {
    try {
      final response = await ApiService.get(
          '${ApiConfig.conversations}$conversationId/messages/');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> data =
            decoded is Map ? (decoded['results'] ?? []) : decoded as List;
        final roleFlag = myRole == 'service_provider' ? -1 : 0;
        return data
            .map((e) => MessageModel.fromJson(e, roleFlag))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<({bool success, String? error})> sendMessage(
      int conversationId, String content) async {
    try {
      final response = await ApiService.post(
        '${ApiConfig.conversations}$conversationId/messages/send/',
        {'content': content},
        authenticated: true,
      );
      if (response.statusCode == 201) return (success: true, error: null);
      return (
        success: false,
        error: '[${response.statusCode}] ${ApiService.extractError(response)}',
      );
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }
}
