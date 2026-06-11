import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/home/cubit/home_cubit.dart';
import 'package:sync_app/features/home/widgets/home_body.dart';
import 'package:sync_app/shared/widgets/sync_app_bar.dart';

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
    return Scaffold(
      backgroundColor: homeBodyBackground,
      appBar: const SyncAppBar(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if ((state.status == HomeStatus.loading || state.status == HomeStatus.initial) &&
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
                      Text(
                        state.error ?? 'Không thể tải dữ liệu',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.read<HomeCubit>().load(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = state.data;
            if (data == null) {
              return const SizedBox.shrink();
            }

            return RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => context.read<HomeCubit>().load(),
              child: HomeBody(data: data),
            );
          },
        ),
      ),
    );
  }
}
