import 'package:image_picker/image_picker.dart';
import 'package:sync_app/features/social/data/social_remote_data_source.dart';
import 'package:sync_app/features/social/models/follow_models.dart';
import 'package:sync_app/features/social/models/social_models.dart';

class SocialRepository {
  SocialRepository(this._remote);

  final SocialRemoteDataSource _remote;

  Future<CursorFeedPage<SocialPost>> loadFeed({
    String? cursor,
    int limit = 20,
    String type = 'following',
  }) =>
      _remote.fetchFeed(cursor: cursor, limit: limit, type: type);

  Future<CursorFeedPage<SocialPost>> loadUserWall({
    required String userId,
    String? cursor,
    int limit = 20,
    bool onlyMedia = false,
  }) =>
      _remote.fetchUserWall(
        userId: userId,
        cursor: cursor,
        limit: limit,
        onlyMedia: onlyMedia,
      );

  Future<void> deletePost(String postId) => _remote.deletePost(postId);

  Future<void> likePost(String postId) => _remote.likePost(postId);

  Future<void> unlikePost(String postId) => _remote.unlikePost(postId);

  Future<void> sharePost(String postId) => _remote.sharePost(postId);

  Future<CommentsPage> fetchComments(String postId, {int pageNumber = 1, int pageSize = 20}) =>
      _remote.fetchComments(postId, pageNumber: pageNumber, pageSize: pageSize);

  Future<SocialComment> createComment({
    required String postId,
    required String content,
    String? authorFullName,
    String? authorAvatarUrl,
  }) =>
      _remote.createComment(
        postId: postId,
        content: content,
        authorFullName: authorFullName,
        authorAvatarUrl: authorAvatarUrl,
      );

  Future<SocialComment> createReply({
    required String commentId,
    required String content,
    required String parentCommentId,
    String? authorFullName,
    String? authorAvatarUrl,
  }) =>
      _remote.createReply(
        commentId: commentId,
        content: content,
        parentCommentId: parentCommentId,
        authorFullName: authorFullName,
        authorAvatarUrl: authorAvatarUrl,
      );

  Future<List<String>> uploadMediaFiles(List<XFile> files) =>
      _remote.uploadMediaFiles(files);

  Future<List<SocialStoryFeedGroup>> loadStoriesFeed() => _remote.fetchStoriesFeed();

  Future<List<SocialStory>> loadMyStories() => _remote.fetchMyStories();

  Future<List<SocialStory>> loadStoriesByUser(String userId) =>
      _remote.fetchStoriesByUser(userId);

  Future<void> viewStory(String storyId) => _remote.viewStory(storyId);

  Future<void> likeStory(String storyId) => _remote.likeStory(storyId);

  Future<SocialStory> createStory({
    required XFile file,
    String? caption,
    required String authorFullName,
    String? authorAvatarUrl,
  }) =>
      _remote.createStory(
        file: file,
        caption: caption,
        authorFullName: authorFullName,
        authorAvatarUrl: authorAvatarUrl,
      );

  Future<FollowCounts> loadFollowCounts(String userId) => _remote.fetchFollowCounts(userId);

  Future<FollowStatus> loadFollowStatus(String userId) => _remote.fetchFollowStatus(userId);

  Future<void> followUser(String userId) => _remote.followUser(userId);

  Future<void> unfollowUser(String userId) => _remote.unfollowUser(userId);

  Future<void> blockUser(String userId) => _remote.blockUser(userId);

  Future<void> reportPost({
    required String postId,
    required String reason,
    String? details,
  }) =>
      _remote.reportContent(
        targetId: postId,
        reason: reason,
        targetType: 'Post',
        details: details,
      );

  Future<void> reportAiContent({
    required String targetId,
    required String reason,
    String? details,
  }) =>
      _remote.reportContent(
        targetId: targetId,
        reason: reason,
        targetType: 'AiContent',
        details: details,
      );

  Future<PagedSearchPage<FollowListItem>> loadFollowers({
    required String userId,
    int pageNumber = 1,
    int pageSize = 20,
  }) =>
      _remote.fetchFollowers(
        userId: userId,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );

  Future<PagedSearchPage<FollowListItem>> loadFollowing({
    required String userId,
    int pageNumber = 1,
    int pageSize = 20,
  }) =>
      _remote.fetchFollowing(
        userId: userId,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );

  Future<PagedSearchPage<SocialPost>> searchPosts({
    required String query,
    int pageNumber = 1,
    int pageSize = 20,
  }) =>
      _remote.searchPosts(query: query, pageNumber: pageNumber, pageSize: pageSize);

  Future<PagedSearchPage<UserSearchResult>> searchUsers({
    required String query,
    int pageNumber = 1,
    int pageSize = 20,
  }) =>
      _remote.searchUsers(query: query, pageNumber: pageNumber, pageSize: pageSize);

  Future<SocialPost> createPost({
    required String content,
    required List<String> mediaUrls,
    required bool isPublic,
    required String authorFullName,
    String? authorAvatarUrl,
    String postType = 'Standard',
  }) =>
      _remote.createPost(
        content: content,
        mediaUrls: mediaUrls,
        isPublic: isPublic,
        authorFullName: authorFullName,
        authorAvatarUrl: authorAvatarUrl,
        postType: postType,
      );
}
