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
      ];
}
