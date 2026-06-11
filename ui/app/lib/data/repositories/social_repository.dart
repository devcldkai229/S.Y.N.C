import 'package:sync_app/features/social/data/social_remote_data_source.dart';
import 'package:sync_app/features/social/models/follow_models.dart';
import 'package:sync_app/features/social/models/social_models.dart';

class SocialRepository {
  SocialRepository(this._remote);

  final SocialRemoteDataSource _remote;

  Future<CursorFeedPage<SocialPost>> loadFeed({String? cursor, int limit = 20}) =>
      _remote.fetchFeed(cursor: cursor, limit: limit);

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

  Future<List<String>> uploadMediaFiles(List<String> filePaths) =>
      _remote.uploadMediaFiles(filePaths);

  Future<List<SocialStoryFeedGroup>> loadStoriesFeed() => _remote.fetchStoriesFeed();

  Future<List<SocialStory>> loadMyStories() => _remote.fetchMyStories();

  Future<void> viewStory(String storyId) => _remote.viewStory(storyId);

  Future<void> likeStory(String storyId) => _remote.likeStory(storyId);

  Future<SocialStory> createStory({
    required String filePath,
    String? caption,
    required String authorFullName,
    String? authorAvatarUrl,
  }) =>
      _remote.createStory(
        filePath: filePath,
        caption: caption,
        authorFullName: authorFullName,
        authorAvatarUrl: authorAvatarUrl,
      );

  Future<FollowCounts> loadFollowCounts(String userId) => _remote.fetchFollowCounts(userId);

  Future<FollowStatus> loadFollowStatus(String userId) => _remote.fetchFollowStatus(userId);

  Future<void> followUser(String userId) => _remote.followUser(userId);

  Future<void> unfollowUser(String userId) => _remote.unfollowUser(userId);

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
