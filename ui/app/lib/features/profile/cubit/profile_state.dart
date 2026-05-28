part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, saving, success, failure }

class ProfileState extends Equatable {
  const ProfileState({
    required this.status,
    this.settings,
    this.inventory,
    this.biometric,
    this.publicProfile,
    this.error,
  });

  const ProfileState.initial() : this(status: ProfileStatus.initial);

  final ProfileStatus status;
  final ProfileSettings? settings;
  final UserInventory? inventory;
  final BiometricProfileDetail? biometric;
  final PublicProfile? publicProfile;
  final String? error;

  bool get isLoading =>
      settings == null &&
      (status == ProfileStatus.loading || status == ProfileStatus.initial);

  bool get isSaving => status == ProfileStatus.saving;

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileSettings? settings,
    UserInventory? inventory,
    BiometricProfileDetail? biometric,
    PublicProfile? publicProfile,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      inventory: inventory ?? this.inventory,
      biometric: biometric ?? this.biometric,
      publicProfile: publicProfile ?? this.publicProfile,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, settings, inventory, biometric, publicProfile, error];
}
