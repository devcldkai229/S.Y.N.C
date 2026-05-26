part of 'home_cubit.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({
    required this.status,
    this.data,
    this.error,
  });

  const HomeState.initial() : this(status: HomeStatus.initial);

  final HomeStatus status;
  final HomeDashboardData? data;
  final String? error;

  HomeState copyWith({
    HomeStatus? status,
    HomeDashboardData? data,
    String? error,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, data, error];
}
