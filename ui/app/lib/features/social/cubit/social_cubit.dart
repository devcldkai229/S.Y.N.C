import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/social/models/social_models.dart';

part 'social_state.dart';

class SocialCubit extends Cubit<SocialState> {
  SocialCubit(this._repository, this._profileApi) : super(const SocialState.initial());

  final SocialRepository _repository;
  final ProfileApiService _profileApi;

  static const _feedLimit = 20;

  Future<void> loadFeed({bool refresh = true}) async {
    if (state.currentUserId.isEmpty) unawaited(_fetchCurrentUserId());

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
      final likedIds = page.items.where((p) => p.isLikedByMe).map((p) => p.id).toList();
      emit(
        state.copyWith(
          status: SocialStatus.success,
          posts: page.items,
          nextCursor: page.nextCursor,
          hasMore: page.nextCursor != null && page.nextCursor!.isNotEmpty,
          isLoadingMore: false,
          likedPostIds: likedIds,
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
      final newLikedIds = page.items.where((p) => p.isLikedByMe).map((p) => p.id).toList();
      emit(
        state.copyWith(
          status: SocialStatus.success,
          posts: merged,
          nextCursor: page.nextCursor,
          hasMore: page.nextCursor != null && page.nextCursor!.isNotEmpty,
          isLoadingMore: false,
          likedPostIds: [...state.likedPostIds, ...newLikedIds],
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
    if (state.likedPostIds.contains(postId)) {
      await _unlikePost(postId);
    } else {
      await _doLikePost(postId);
    }
  }

  Future<void> deletePost(String postId) async {
    await _repository.deletePost(postId);
    emit(
      state.copyWith(
        posts: state.posts.where((p) => p.id != postId).toList(),
        likedPostIds: state.likedPostIds.where((id) => id != postId).toList(),
        sharedPostIds: state.sharedPostIds.where((id) => id != postId).toList(),
        hiddenPostIds: state.hiddenPostIds.where((id) => id != postId).toList(),
      ),
    );
  }

  void hidePost(String postId) {
    if (state.hiddenPostIds.contains(postId)) return;
    emit(state.copyWith(hiddenPostIds: [...state.hiddenPostIds, postId]));
  }

  void unhidePost(String postId) {
    emit(state.copyWith(
      hiddenPostIds: state.hiddenPostIds.where((id) => id != postId).toList(),
    ));
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
    } catch (_) {}
  }

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

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<void> _fetchCurrentUserId() async {
    try {
      final settings = await _profileApi.getProfileSettings();
      if (!isClosed) emit(state.copyWith(currentUserId: settings.userId));
    } catch (_) {}
  }

  Future<void> _doLikePost(String postId) async {
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
      emit(state.copyWith(posts: posts, likedPostIds: [...state.likedPostIds, postId]));
    } catch (_) {}
  }

  Future<void> _unlikePost(String postId) async {
    try {
      await _repository.unlikePost(postId);
      final posts = [...state.posts];
      final idx = posts.indexWhere((p) => p.id == postId);
      if (idx >= 0) {
        final post = posts[idx];
        posts[idx] = post.copyWith(
          isLikedByMe: false,
          metrics: SocialPostMetrics(
            likeCount: post.metrics.likeCount > 0 ? post.metrics.likeCount - 1 : 0,
            commentCount: post.metrics.commentCount,
            shareCount: post.metrics.shareCount,
          ),
        );
      }
      emit(state.copyWith(
        posts: posts,
        likedPostIds: state.likedPostIds.where((id) => id != postId).toList(),
      ));
    } catch (_) {}
  }
}
