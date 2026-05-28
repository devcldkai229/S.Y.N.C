import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/social/models/social_models.dart';

part 'social_state.dart';

class SocialCubit extends Cubit<SocialState> {
  SocialCubit(this._repository) : super(const SocialState.initial());

  final SocialRepository _repository;

  static const _feedLimit = 20;

  Future<void> loadFeed({bool refresh = true}) async {
    if (refresh) {
      emit(
        state.copyWith(
          status: SocialStatus.loading,
          clearError: true,
          posts: const [],
          nextCursor: null,
          hasMore: false,
          isLoadingMore: false,
          likedPostIds: const [],
          sharedPostIds: const [],
        ),
      );
    } else {
      emit(state.copyWith(status: SocialStatus.loading, clearError: true));
    }

    try {
      final page = await _repository.loadFeed(cursor: null, limit: _feedLimit);
      emit(
        state.copyWith(
          status: SocialStatus.success,
          posts: page.items,
          nextCursor: page.nextCursor,
          hasMore: page.nextCursor != null && page.nextCursor!.isNotEmpty,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SocialStatus.failure, error: mapApiError(e)));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final cursor = state.nextCursor;
    if (cursor == null || cursor.isEmpty) return;

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final page = await _repository.loadFeed(cursor: cursor, limit: _feedLimit);
      final merged = [...state.posts, ...page.items];
      emit(
        state.copyWith(
          status: SocialStatus.success,
          posts: merged,
          nextCursor: page.nextCursor,
          hasMore: page.nextCursor != null && page.nextCursor!.isNotEmpty,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(
        status: SocialStatus.failure,
        error: mapApiError(e),
        isLoadingMore: false,
      ));
    }
  }

  Future<void> likePost(String postId) async {
    if (state.likedPostIds.contains(postId)) return;

    try {
      await _repository.likePost(postId);
      final posts = [...state.posts];
      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx < 0) return;
      final post = posts[idx];
      posts[idx] = post.copyWith(
        isLikedByMe: true,
        metrics: SocialPostMetrics(
          likeCount: post.metrics.likeCount + 1,
          commentCount: post.metrics.commentCount,
          shareCount: post.metrics.shareCount,
        ),
      );
      emit(
        state.copyWith(
          posts: posts,
          likedPostIds: [...state.likedPostIds, postId],
        ),
      );
    } catch (_) {
      // Conflict nếu đã like rồi — ignore.
    }
  }

  Future<void> sharePost(String postId) async {
    if (state.sharedPostIds.contains(postId)) return;

    try {
      await _repository.sharePost(postId);
      final posts = [...state.posts];
      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx < 0) return;
      final post = posts[idx];
      posts[idx] = post.copyWith(
        isSharedByMe: true,
        metrics: SocialPostMetrics(
          likeCount: post.metrics.likeCount,
          commentCount: post.metrics.commentCount,
          shareCount: post.metrics.shareCount + 1,
        ),
      );
      emit(
        state.copyWith(
          posts: posts,
          sharedPostIds: [...state.sharedPostIds, postId],
        ),
      );
    } catch (_) {
      // Conflict nếu đã share rồi — ignore.
    }
  }

  /// Cập nhật số comment trên một bài trong feed (sau khi gửi comment thành công).
  void bumpCommentCount(String postId) {
    final posts = [...state.posts];
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = posts[idx];
    posts[idx] = post.copyWith(
      metrics: SocialPostMetrics(
        likeCount: post.metrics.likeCount,
        commentCount: post.metrics.commentCount + 1,
        shareCount: post.metrics.shareCount,
      ),
    );
    emit(state.copyWith(posts: posts));
  }
}
