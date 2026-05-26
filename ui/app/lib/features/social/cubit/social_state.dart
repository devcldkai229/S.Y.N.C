part of 'social_cubit.dart';

enum SocialStatus { initial, loading, success, failure }

class SocialState extends Equatable {
  const SocialState({
    required this.status,
    this.posts = const [],
    this.error,
  });

  const SocialState.initial() : this(status: SocialStatus.initial);

  final SocialStatus status;
  final List<SocialPost> posts;
  final String? error;

  SocialState copyWith({
    SocialStatus? status,
    List<SocialPost>? posts,
    String? error,
    bool clearError = false,
  }) {
    return SocialState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, posts, error];
}
