import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/home/cubit/home_cubit.dart';
import 'package:sync_app/features/home/widgets/home_app_bar.dart';
import 'package:sync_app/features/home/widgets/recovery_score_card.dart';
import 'package:sync_app/features/home/widgets/roadmap_card.dart';
import 'package:sync_app/features/home/widgets/schedule_card.dart';
import 'package:sync_app/features/home/widgets/wallet_card.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(getIt())..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const HomeAppBar(),
            Expanded(
                child: BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, state) {
                    if ((state.status == HomeStatus.loading ||
                            state.status == HomeStatus.initial) &&
                        state.data == null) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryGreen),
                      );
                    }
                    if (state.status == HomeStatus.failure && state.data == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(state.error ?? 'Failed to load', textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => context.read<HomeCubit>().load(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final d = state.data;
                    return RefreshIndicator(
                      color: AppColors.primaryGreen,
                      onRefresh: () => context.read<HomeCubit>().load(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Morning, ${d?.greetingName ?? 'Athlete'}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              d?.subtitle ?? 'Loading your plan...',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            RoadmapCard(
                              phaseLabel: d?.phaseLabel,
                              weekLabel: d?.weekLabel,
                              goalLabel: d?.goalLabel,
                              progress: d?.phaseProgress ?? 0,
                              hint: d?.progressHint,
                            ),
                            const SizedBox(height: 16),
                            RecoveryScoreCard(score: d?.recoveryScore, hint: d?.recoveryHint),
                            const SizedBox(height: 16),
                            ScheduleCard(
                              sessionTitle: d?.todaySessionTitle,
                              sessionTime: d?.todaySessionTime,
                              sessionMeta: d?.todaySessionMeta,
                              intensityBars: d?.sessionIntensityBars ?? 2,
                            ),
                            const SizedBox(height: 16),
                            WalletCard(
                              syncCoins: d?.syncCoins ?? 0,
                              subscriptionTier: d?.subscriptionTier ?? 'Free',
                              hint: d?.walletHint,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
