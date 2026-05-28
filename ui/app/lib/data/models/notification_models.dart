import 'package:sync_app/core/models/api_models.dart';

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? imageUrl;

  bool get isRead {
    final s = status.toLowerCase();
    return readAt != null || s == 'read';
  }

  AppNotification copyWith({DateTime? readAt, String? status}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      status: status ?? this.status,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      type: _enumLabel(json['type']),
      status: _enumLabel(json['status']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  String get timeAgoLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.month}/${createdAt.day}';
  }
}

class NotificationsPage {
  NotificationsPage({
    required this.items,
    required this.pagination,
  });

  final List<AppNotification> items;
  final PaginationMeta pagination;
}

String _enumLabel(dynamic value) {
  if (value == null) return '';
  final s = value.toString();
  return s.contains('.') ? s.split('.').last : s;
}
