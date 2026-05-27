import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/social/models/social_models.dart';

part 'social_state.dart';

class SocialCubit extends Cubit<SocialState> {
  SocialCubit(this._repository) : super(const SocialState.initial());

  final SocialRepository _repository;

  Future<void> loadFeed() async {
    emit(state.copyWith(status: SocialStatus.loading, clearError: true));
    try {
      final posts = await _repository.loadFeed();
      emit(state.copyWith(status: SocialStatus.success, posts: posts));
    } catch (e) {
      emit(state.copyWith(status: SocialStatus.failure, error: mapApiError(e)));
    }
  }

  void toggleLike(String postId) {
    final posts = [...state.posts];
    final index = posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;

    final post = posts[index];
    final wasLiked = post.isLikedByMe;
    var likes = post.likeCount;
    var dislikes = post.dislikeCount;
    var disliked = post.isDislikedByMe;

    if (wasLiked) {
      likes--;
    } else {
      likes++;
      if (disliked) {
        dislikes--;
        disliked = false;
      }
    }

    final updated = post.copyWith(
      isLikedByMe: !wasLiked,
      isDislikedByMe: disliked,
      likeCount: likes,
      dislikeCount: dislikes,
    );
    posts[index] = updated;
    emit(state.copyWith(posts: posts));
    _repository.syncLike(postId, !wasLiked);
  }

  void toggleDislike(String postId) {
    final posts = [...state.posts];
    final index = posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;

    final post = posts[index];
    final wasDisliked = post.isDislikedByMe;
    var likes = post.likeCount;
    var dislikes = post.dislikeCount;
    var liked = post.isLikedByMe;

    if (wasDisliked) {
      dislikes--;
    } else {
      dislikes++;
      if (liked) {
        likes--;
        liked = false;
      }
    }

    final updated = post.copyWith(
      isDislikedByMe: !wasDisliked,
      isLikedByMe: liked,
      likeCount: likes,
      dislikeCount: dislikes,
    );
    posts[index] = updated;
    emit(state.copyWith(posts: posts));
    _repository.syncDislike(postId, !wasDisliked);
  }

  Future<void> addComment(String postId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    final comment = await _repository.addComment(postId, trimmed);
    final posts = [...state.posts];
    final index = posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;

    final post = posts[index];
    final comments = [...post.comments, comment];
    posts[index] = post.copyWith(
      comments: comments,
      commentCount: post.commentCount + 1,
    );
    emit(state.copyWith(posts: posts));
  }
}
