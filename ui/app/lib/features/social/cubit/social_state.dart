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
    this.currentUser,
    this.hiddenPostIds = const [],
    this.storyGroups = const [],
    this.myStories = const [],
    this.showStoriesRow = true,
    this.seenStoryAuthorIds = const {},
    this.snackbarError,
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
  final SocialAuthorSnapshot? currentUser;
  final List<String> hiddenPostIds;
  final List<SocialStoryFeedGroup> storyGroups;
  final List<SocialStory> myStories;
  final bool showStoriesRow;
  final Set<String> seenStoryAuthorIds;
  final String? snackbarError;

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
    SocialAuthorSnapshot? currentUser,
    List<String>? hiddenPostIds,
    List<SocialStoryFeedGroup>? storyGroups,
    List<SocialStory>? myStories,
    bool? showStoriesRow,
    Set<String>? seenStoryAuthorIds,
    String? snackbarError,
    bool clearSnackbarError = false,
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
      currentUser: currentUser ?? this.currentUser,
      hiddenPostIds: hiddenPostIds ?? this.hiddenPostIds,
      storyGroups: storyGroups ?? this.storyGroups,
      myStories: myStories ?? this.myStories,
      showStoriesRow: showStoriesRow ?? this.showStoriesRow,
      seenStoryAuthorIds: seenStoryAuthorIds ?? this.seenStoryAuthorIds,
      snackbarError: clearSnackbarError ? null : (snackbarError ?? this.snackbarError),
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
        currentUser,
        hiddenPostIds,
        storyGroups,
        myStories,
        showStoriesRow,
        seenStoryAuthorIds,
        snackbarError,
      ];
}
