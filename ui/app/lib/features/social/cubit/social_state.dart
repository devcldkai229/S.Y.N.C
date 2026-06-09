part of 'social_cubit.dart';

enum SocialStatus { initial, loading, success, failure }

class SocialState extends Equatable {
  const SocialState({
    required this.status,
    this.posts = const [],
    this.error,
    this.nextCursor,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.likedPostIds = const [],
    this.sharedPostIds = const [],
    this.currentUserId = '',
    this.hiddenPostIds = const [],
  });

  const SocialState.initial() : this(status: SocialStatus.initial);

  final SocialStatus status;
  final List<SocialPost> posts;
  final String? error;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final List<String> likedPostIds;
  final List<String> sharedPostIds;
  final String currentUserId;
  final List<String> hiddenPostIds;

  /// Posts visible to the user (excludes locally hidden posts).
  List<SocialPost> get visiblePosts =>
      hiddenPostIds.isEmpty ? posts : posts.where((p) => !hiddenPostIds.contains(p.id)).toList();

  SocialState copyWith({
    SocialStatus? status,
    List<SocialPost>? posts,
    String? error,
    bool clearError = false,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
    List<String>? likedPostIds,
    List<String>? sharedPostIds,
    String? currentUserId,
    List<String>? hiddenPostIds,
  }) {
    return SocialState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      error: clearError ? null : (error ?? this.error),
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      likedPostIds: likedPostIds ?? this.likedPostIds,
      sharedPostIds: sharedPostIds ?? this.sharedPostIds,
      currentUserId: currentUserId ?? this.currentUserId,
      hiddenPostIds: hiddenPostIds ?? this.hiddenPostIds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        posts,
        error,
        nextCursor,
        hasMore,
        isLoadingMore,
        likedPostIds,
        sharedPostIds,
        currentUserId,
        hiddenPostIds,
      ];
}
