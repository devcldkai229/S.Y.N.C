class FollowCounts {
  const FollowCounts({
    required this.followerCount,
    required this.followingCount,
  });

  final int followerCount;
  final int followingCount;

  factory FollowCounts.fromJson(Map<String, dynamic> json) {
    return FollowCounts(
      followerCount: _asInt(json['followerCount']),
      followingCount: _asInt(json['followingCount']),
    );
  }

  static const empty = FollowCounts(followerCount: 0, followingCount: 0);
}

class FollowListItem {
  const FollowListItem({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.followedAt,
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final DateTime followedAt;

  factory FollowListItem.fromJson(Map<String, dynamic> json) {
    return FollowListItem(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Người dùng',
      avatarUrl: json['avatarUrl']?.toString(),
      followedAt: DateTime.tryParse(json['followedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class FollowStatus {
  const FollowStatus({
    this.outgoingStatus,
    this.hasIncomingPendingRequest = false,
    this.isBlockedBetween = false,
    this.canFollow = true,
    this.canViewContent = true,
  });

  final String? outgoingStatus;
  final bool hasIncomingPendingRequest;
  final bool isBlockedBetween;
  final bool canFollow;
  final bool canViewContent;

  bool get isFollowing => outgoingStatus == 'Accepted';
  bool get isPending => outgoingStatus == 'Pending';

  factory FollowStatus.fromJson(Map<String, dynamic> json) {
    return FollowStatus(
      outgoingStatus: json['outgoingStatus']?.toString(),
      hasIncomingPendingRequest: json['hasIncomingPendingRequest'] == true,
      isBlockedBetween: json['isBlockedBetween'] == true,
      canFollow: json['canFollow'] != false,
      canViewContent: json['canViewContent'] != false,
    );
  }

  static const none = FollowStatus();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
