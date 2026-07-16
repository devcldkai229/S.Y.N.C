import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/features/blogs/data/blog_repository.dart';
import 'package:sync_app/features/blogs/models/blog_models.dart';

enum BlogDetailStatus { initial, loading, success, failure }

class BlogDetailState extends Equatable {
  const BlogDetailState({
    this.status = BlogDetailStatus.initial,
    this.blog,
    this.comments = const [],
    this.commentPage = 1,
    this.commentsHasMore = false,
    this.isSubmittingComment = false,
    this.isLiking = false,
    this.error,
  });

  final BlogDetailStatus status;
  final BlogPost? blog;
  final List<BlogComment> comments;
  final int commentPage;
  final bool commentsHasMore;
  final bool isSubmittingComment;
  final bool isLiking;
  final String? error;

  BlogDetailState copyWith({
    BlogDetailStatus? status,
    BlogPost? blog,
    List<BlogComment>? comments,
    int? commentPage,
    bool? commentsHasMore,
    bool? isSubmittingComment,
    bool? isLiking,
    String? error,
  }) {
    return BlogDetailState(
      status: status ?? this.status,
      blog: blog ?? this.blog,
      comments: comments ?? this.comments,
      commentPage: commentPage ?? this.commentPage,
      commentsHasMore: commentsHasMore ?? this.commentsHasMore,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      isLiking: isLiking ?? this.isLiking,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        blog,
        comments,
        commentPage,
        commentsHasMore,
        isSubmittingComment,
        isLiking,
        error,
      ];
}

class BlogDetailCubit extends Cubit<BlogDetailState> {
  BlogDetailCubit(this._repo, this.blogId) : super(const BlogDetailState());

  final BlogRepository _repo;
  final String blogId;

  Future<void> load() async {
    emit(state.copyWith(status: BlogDetailStatus.loading, error: null));
    try {
      final blog = await _repo.getById(blogId);
      final comments = await _repo.loadComments(blogId);
      emit(state.copyWith(
        status: BlogDetailStatus.success,
        blog: blog,
        comments: comments.items,
        commentPage: comments.pageNumber,
        commentsHasMore: comments.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(status: BlogDetailStatus.failure, error: e.toString()));
    }
  }

  Future<void> like() async {
    final blog = state.blog;
    if (blog == null || blog.isLikedByMe || state.isLiking) return;
    emit(state.copyWith(isLiking: true));
    try {
      final result = await _repo.like(blogId);
      emit(state.copyWith(
        isLiking: false,
        blog: blog.copyWith(likeCount: result.likeCount, isLikedByMe: true),
      ));
    } catch (e) {
      emit(state.copyWith(isLiking: false, error: e.toString()));
    }
  }

  Future<void> submitComment({
    required String content,
    String? authorFullName,
    String? authorAvatarUrl,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || state.isSubmittingComment) return;

    emit(state.copyWith(isSubmittingComment: true, error: null));
    try {
      final comment = await _repo.createComment(
        blogId: blogId,
        content: trimmed,
        authorFullName: authorFullName,
        authorAvatarUrl: authorAvatarUrl,
      );
      final blog = state.blog;
      emit(state.copyWith(
        isSubmittingComment: false,
        comments: [comment, ...state.comments],
        blog: blog?.copyWith(commentCount: (blog.commentCount) + 1),
      ));
    } catch (e) {
      emit(state.copyWith(isSubmittingComment: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> loadMoreComments() async {
    if (!state.commentsHasMore) return;
    try {
      final page = await _repo.loadComments(blogId, pageNumber: state.commentPage + 1);
      emit(state.copyWith(
        comments: [...state.comments, ...page.items],
        commentPage: page.pageNumber,
        commentsHasMore: page.hasMore,
      ));
    } catch (_) {}
  }
}
