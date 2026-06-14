import 'dart:convert';

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
    this.deepLink,
    this.dataPayloadJson,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String status;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? imageUrl;
  final String? deepLink;
  final String? dataPayloadJson;

  bool get isRead {
    final s = status.toLowerCase();
    return readAt != null || s == 'read';
  }

  Map<String, dynamic> get payload {
    if (dataPayloadJson == null || dataPayloadJson!.isEmpty) return const {};
    try {
      final decoded = jsonDecode(dataPayloadJson!);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  String? get actorId => payload['actorId']?.toString();
  String? get postId => payload['postId']?.toString();
  String? get commentId => payload['commentId']?.toString();
  String? get storyId => payload['storyId']?.toString();
  String? get challengeId => payload['challengeId']?.toString();

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
      deepLink: deepLink,
      dataPayloadJson: dataPayloadJson,
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
      deepLink: json['deepLink']?.toString(),
      dataPayloadJson: json['dataPayloadJson']?.toString(),
    );
  }

  String get timeAgoLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${createdAt.day}/${createdAt.month}';
  }

  bool get isSocialType {
    final t = type.toLowerCase();
    return t.contains('post') ||
        t.contains('comment') ||
        t.contains('follow') ||
        t.contains('story') ||
        t.contains('challenge');
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
