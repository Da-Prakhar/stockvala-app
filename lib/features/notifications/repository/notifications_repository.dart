import '../../../core/network/api_client.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'trade', 'account', 'system', 'deposit'
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id']?.toString() ?? '',
    title: j['title'] as String? ?? '',
    // body: backend may send 'body', 'message', or 'content'
    body: j['body'] as String? ?? j['message'] as String? ?? j['content'] as String? ?? '',
    type: j['type'] as String? ?? 'system',
    // backend may send isRead (camelCase) or is_read (snake_case)
    isRead: j['isRead'] as bool? ?? j['is_read'] as bool? ?? j['read'] as bool? ?? false,
    createdAt: DateTime.tryParse(
          j['createdAt'] as String? ?? j['created_at'] as String? ?? '',
        ) ?? DateTime.now(),
    data: j['data'] as Map<String, dynamic>?,
  );
}

class NotificationsRepository {
  static final NotificationsRepository instance = NotificationsRepository._();
  NotificationsRepository._();

  final _api = ApiClient.instance;

  Future<List<AppNotification>> getNotifications({int page = 1, int limit = 30}) async {
    try {
      final res = await _api.get('/notifications', params: {'page': page, 'limit': limit});
      final body = res.data as Map<String, dynamic>;
      final list = body['data'] as List<dynamic>? ?? [];
      return list.map((j) => AppNotification.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      throw extractApiException(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.put('/notifications/$id/read');
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _api.put('/notifications/read-all');
    } catch (_) {}
  }

  Future<int> getUnreadCount() async {
    try {
      final res = await _api.get('/notifications/unread');
      // v7 envelope: {data: {unreadCount: n}}
      final d = res.data?['data'];
      return ((d is Map ? d['unreadCount'] : res.data?['count']) as num? ?? 0).toInt();
    } catch (_) {
      return 0;
    }
  }
}
