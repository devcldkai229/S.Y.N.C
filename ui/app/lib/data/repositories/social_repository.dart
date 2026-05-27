import 'package:sync_app/features/social/data/social_remote_data_source.dart';
import 'package:sync_app/features/social/models/social_models.dart';

class SocialRepository {
  SocialRepository(this._remote);

  final SocialRemoteDataSource _remote;

  Future<List<SocialPost>> loadFeed() => _remote.fetchFeed();

  Future<void> syncLike(String postId, bool like) => _remote.toggleLike(postId, like);

  Future<void> syncDislike(String postId, bool dislike) =>
      _remote.toggleDislike(postId, dislike);

  Future<SocialComment> addComment(String postId, String content) =>
      _remote.addComment(postId, content);
}
