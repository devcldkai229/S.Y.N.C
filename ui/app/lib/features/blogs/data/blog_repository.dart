import 'package:sync_app/features/blogs/data/blog_remote_data_source.dart';
import 'package:sync_app/features/blogs/models/blog_models.dart';

class BlogRepository {
  BlogRepository(this._remote);

  final BlogRemoteDataSource _remote;

  Future<BlogPage> loadPublished({int pageNumber = 1, int pageSize = 20}) =>
      _remote.fetchPublished(pageNumber: pageNumber, pageSize: pageSize);

  Future<BlogPage> search({required String q, int pageNumber = 1, int pageSize = 20}) =>
      _remote.search(q: q, pageNumber: pageNumber, pageSize: pageSize);

  Future<BlogPost> getById(String blogId) => _remote.fetchById(blogId);

  Future<({int likeCount, int shareCount})> like(String blogId) => _remote.like(blogId);

  Future<BlogCommentsPage> loadComments(String blogId, {int pageNumber = 1}) =>
      _remote.fetchComments(blogId, pageNumber: pageNumber);

  Future<BlogComment> createComment({
    required String blogId,
    required String content,
    String? authorFullName,
    String? authorAvatarUrl,
  }) =>
      _remote.createComment(
        blogId: blogId,
        content: content,
        authorFullName: authorFullName,
        authorAvatarUrl: authorAvatarUrl,
      );
}
