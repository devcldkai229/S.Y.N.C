part of 'achievements_cubit.dart';

enum AchievementsStatus { initial, loading, success, failure }

class AchievementsState extends Equatable {
  const AchievementsState({
    this.status = AchievementsStatus.initial,
    this.inventory,
    this.error,
  });

  final AchievementsStatus status;
  final UserInventory? inventory;
  final String? error;

  bool get isLoading => status == AchievementsStatus.loading;

  @override
  List<Object?> get props => [status, inventory, error];

  AchievementsState copyWith({
    AchievementsStatus? status,
    UserInventory? inventory,
    String? error,
    bool clearError = false,
  }) {
    return AchievementsState(
      status: status ?? this.status,
      inventory: inventory ?? this.inventory,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
