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
  static const _likeDebounceMs = 300;

  final Map<String, Timer> _likeDebounceTimers = {};
  final Map<String, bool> _pendingLikeTarget = {};

  Future<void> loadAll({bool refresh = true}) async {
    await Future.wait([
      _loadCurrentUser(),
      loadStories(),
      loadFeed(refresh: refresh),
    ]);
  }

  Future<void> _loadCurrentUser() async {
    try {
      final settings = await _profileApi.getProfileSettings();
      if (isClosed) return;
      emit(
        state.copyWith(
          currentUserId: settings.userId,
          currentUser: SocialAuthorSnapshot(
            fullName: settings.basic.fullName.isNotEmpty ? settings.basic.fullName : 'Bạn',
            avatarUrl: settings.basic.avatarUrl,
          ),
        ),
      );
      await _loadMyStories();
    } catch (_) {}
  }

  Future<void> _loadMyStories() async {
    try {
      final stories = await _repository.loadMyStories();
      if (!isClosed) emit(state.copyWith(myStories: stories));
    } catch (_) {}
  }

  Future<void> loadStories() async {
    try {
      final groups = await _repository.loadStoriesFeed();
      if (!isClosed) {
        emit(state.copyWith(storyGroups: groups, showStoriesRow: true));
      }
    } catch (_) {
      // Keep the row visible so "Tạo tin" still works when feed API fails.
      if (!isClosed) {
        emit(state.copyWith(storyGroups: const [], showStoriesRow: true));
      }
    }
  }

  Future<void> refreshStories() async {
    await Future.wait([loadStories(), _loadMyStories()]);
  }

  Future<void> loadFeed({bool refresh = true}) async {
    if (state.currentUserId.isEmpty) unawaited(_loadCurrentUser());

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
    } else if (state.status == SocialStatus.initial) {
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
      emit(
        state.copyWith(
          status: SocialStatus.failure,
          error: mapApiError(e),
          isLoadingMore: false,
        ),
      );
    }
  }

  void toggleLike(String postId) {
    final currentlyLiked = state.likedPostIds.contains(postId);
    final targetLiked = !currentlyLiked;
    _pendingLikeTarget[postId] = targetLiked;

    _applyLikeLocally(postId, liked: targetLiked);

    _likeDebounceTimers[postId]?.cancel();
    _likeDebounceTimers[postId] = Timer(
      const Duration(milliseconds: _likeDebounceMs),
      () => _flushLike(postId),
    );
  }

  void _applyLikeLocally(String postId, {required bool liked}) {
    final posts = [...state.posts];
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return;

    final post = posts[idx];
    final delta = liked ? 1 : -1;
    final newCount = (post.metrics.likeCount + delta).clamp(0, 1 << 30);

    posts[idx] = post.copyWith(
      isLikedByMe: liked,
      metrics: SocialPostMetrics(
        likeCount: newCount,
        commentCount: post.metrics.commentCount,
        shareCount: post.metrics.shareCount,
      ),
    );

    final likedIds = liked
        ? [...state.likedPostIds, postId]
        : state.likedPostIds.where((id) => id != postId).toList();

    emit(state.copyWith(posts: posts, likedPostIds: likedIds));
  }

  Future<void> _flushLike(String postId) async {
    final targetLiked = _pendingLikeTarget.remove(postId);
    _likeDebounceTimers.remove(postId);
    if (targetLiked == null) return;

    final snapshotLiked = state.likedPostIds.contains(postId);
    if (snapshotLiked != targetLiked) return;

    try {
      if (targetLiked) {
        await _repository.likePost(postId);
      } else {
        await _repository.unlikePost(postId);
      }
    } catch (e) {
      _applyLikeLocally(postId, liked: !targetLiked);
      if (!isClosed) {
        emit(state.copyWith(snackbarError: mapApiError(e)));
      }
    }
  }

  void clearSnackbarError() {
    if (state.snackbarError != null) {
      emit(state.copyWith(clearSnackbarError: true));
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

  Future<bool> sharePost(String postId) async {
    if (state.sharedPostIds.contains(postId)) return true;

    final posts = [...state.posts];
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return false;

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

    try {
      await _repository.sharePost(postId);
      return true;
    } catch (e) {
      final revertPosts = [...state.posts];
      final revertIdx = revertPosts.indexWhere((p) => p.id == postId);
      if (revertIdx >= 0) {
        final original = revertPosts[revertIdx];
        revertPosts[revertIdx] = original.copyWith(
          isSharedByMe: false,
          metrics: SocialPostMetrics(
            likeCount: original.metrics.likeCount,
            commentCount: original.metrics.commentCount,
            shareCount: original.metrics.shareCount > 0 ? original.metrics.shareCount - 1 : 0,
          ),
        );
      }
      emit(
        state.copyWith(
          posts: revertPosts,
          sharedPostIds: state.sharedPostIds.where((id) => id != postId).toList(),
          snackbarError: mapApiError(e),
        ),
      );
      return false;
    }
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

  Future<void> viewStory(SocialStory story, {required String authorId}) async {
    try {
      await _repository.viewStory(story.id);
      if (!isClosed) {
        emit(
          state.copyWith(
            seenStoryAuthorIds: {...state.seenStoryAuthorIds, authorId},
          ),
        );
      }
    } catch (_) {}
  }

  Future<bool> likeStory(String storyId) async {
    try {
      await _repository.likeStory(storyId);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> close() {
    for (final timer in _likeDebounceTimers.values) {
      timer.cancel();
    }
    _likeDebounceTimers.clear();
    return super.close();
  }
}
