part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, saving, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    required this.status,
    this.settings,
    this.inventory,
    this.error,
  });

  const ProfileState.initial() : this(status: ProfileStatus.initial);

  final ProfileStatus status;
  final ProfileSettings? settings;
  final UserInventory? inventory;
  final String? error;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileSettings? settings,
    UserInventory? inventory,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      inventory: inventory ?? this.inventory,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, settings, inventory, error];
}
