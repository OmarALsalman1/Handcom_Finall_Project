import 'dart:convert';
import 'api_service.dart';
import '../core/config/api_config.dart';

class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final int? relatedRequestId;
  final int? relatedConversationId;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.relatedRequestId,
    this.relatedConversationId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['notification_id'] ?? 0,
      type: json['notification_type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      relatedRequestId: json['related_request_id'] as int?,
      relatedConversationId: json['related_conversation_id'] as int?,
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        type: type,
        title: title,
        body: body,
        relatedRequestId: relatedRequestId,
        relatedConversationId: relatedConversationId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  String get timeAgo => timeAgoLabel(false);

  String timeAgoLabel(bool isAr) {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (isAr) {
        if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
        if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
        return 'منذ ${diff.inDays} يوم';
      } else {
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        return '${diff.inDays}d ago';
      }
    } catch (_) {
      return '';
    }
  }

  static Future<int> getUnreadCount() async {
    try {
      final response = await ApiService.get(ApiConfig.notificationsUnreadCount);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return (data['unread_count'] ?? 0) as int;
      }
    } catch (_) {}
    return 0;
  }
}

class NotificationService {
  static Future<ListResult<NotificationModel>> getNotifications() async {
    try {
      final response = await ApiService.get(ApiConfig.notifications);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final List<dynamic> data =
            decoded is Map ? (decoded['results'] ?? []) : decoded as List;
        return ListResult.success(
            data.map((e) => NotificationModel.fromJson(e)).toList());
      }
      return ListResult.failure(ApiService.extractErrorCode(response));
    } on ApiException catch (e) {
      return ListResult.failure(e.code);
    } catch (_) {
      return const ListResult.failure('server_error');
    }
  }

  static Future<void> markAllRead() async {
    try {
      await ApiService.patch(ApiConfig.notificationsReadAll, {});
    } catch (_) {}
  }

  static Future<void> markRead(int id) async {
    try {
      await ApiService.patch('${ApiConfig.notifications}$id/read/', {});
    } catch (_) {}
  }
}
