import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_cart_cubit.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_home_cubit.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_affiliate_card.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_affiliate_redirect_sheet.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_cart_sheet.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_category_circle.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_featured_dish_card.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_hero_banner.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_home_skeleton.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_immersive_header.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_promo_carousel.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_location_picker_sheet.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_section_header.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_shortcut_card.dart';
import 'package:sync_app/features/order/state/active_order_count_notifier.dart';
import 'package:sync_app/shared/widgets/app_shell_overlay_scaffold.dart';

class MarketplaceHomeScreen extends StatelessWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        getIt<MarketplaceCartCubit>().hydrate();
        getIt<ActiveOrderCountNotifier>().refresh();
        return getIt<MarketplaceHomeCubit>()..init();
      },
      child: const AppShellOverlayScaffold(child: _MarketplaceHomeView()),
    );
  }
}

class _MarketplaceHomeView extends StatelessWidget {
  const _MarketplaceHomeView();

  String _deliveryLabel(MarketplaceHomeState state) {
    if (state.locationStatus == MarketplaceLocationStatus.resolving) {
      return 'Đang định vị…';
    }
    if (state.delivery != null) {
      return state.delivery!.shortLabel;
    }
    return 'Chọn vị trí';
  }

  Future<void> _openLocationPicker(BuildContext context) async {
    final cubit = context.read<MarketplaceHomeCubit>();
    final picked = await MarketplaceLocationPickerScreen.show(
      context,
      initial: cubit.state.delivery,
    );
    if (picked != null) cubit.setDeliveryLocation(picked);
  }

  Future<void> _onAffiliateTap(BuildContext context, AffiliateProduct product) async {
    await context.read<MarketplaceHomeCubit>().trackAffiliateClick(product.id);
    if (!context.mounted) return;
    await MarketplaceAffiliateRedirectSheet.show(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarketplaceTheme.background,
      body: BlocBuilder<MarketplaceHomeCubit, MarketplaceHomeState>(
        builder: (context, state) {
          final cubit = context.read<MarketplaceHomeCubit>();
          final data = state.data;
          final cart = context.watch<MarketplaceCartCubit>().state;

          return RefreshIndicator(
            color: MarketplaceTheme.primary,
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: MarketplaceImmersiveHeader(
                    locationStatus: state.locationStatus,
                    deliveryLabel: _deliveryLabel(state),
                    onLocationTap: () => _openLocationPicker(context),
                    onSearchTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tìm kiếm sẽ sớm ra mắt'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    cartItemCount: cart.itemCount,
                    onCartTap: cart.items.isEmpty
                        ? null
                        : () => MarketplaceCartSheet.show(context),
                  ),
                ),
                const SliverToBoxAdapter(child: MarketplaceHeroBanner()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (state.isLoading && data == null)
                  const SliverToBoxAdapter(child: MarketplaceHomeSkeleton())
                else if (state.status == MarketplaceHomeStatus.failure && data == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _SectionError(
                      message: state.error ?? 'Không tải được dữ liệu',
                      onRetry: cubit.refresh,
                    ),
                  )
                else if (data != null) ...[
                  SliverToBoxAdapter(
                    child: MarketplaceCategoryRow(
                      categories: data.categories,
                      selectedId: state.selectedCategoryId,
                      onSelected: cubit.selectCategory,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: MarketplaceShortcutRow(
                      shortcuts: data.shortcuts,
                      onTap: (s) {
                        if (s.filterTag != null) {
                          cubit.selectCategory(s.filterTag == 'nearby' ? null : s.filterTag);
                        }
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(child: MarketplacePromoCarousel()),
                  SliverToBoxAdapter(
                    child: MarketplaceSectionHeader(
                      title: 'Gợi ý cho bạn',
                      trailing: TextButton(
                        onPressed: () {},
                        child: const Text('XEM TẤT CẢ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ),
                  ),
                  if (data.featured.isEmpty)
                    SliverToBoxAdapter(
                      child: _SectionEmpty(
                        message: 'Chưa có gợi ý phù hợp — thử danh mục khác nhé',
                        onRetry: cubit.refresh,
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: MarketplaceFeaturedRow(
                        dishes: data.featured,
                        onDishTap: (d) => context.push(AppRoutes.marketplaceFoodItem(d.item.id)),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: MarketplaceSectionHeader(
                      title: 'Sản phẩm bổ trợ',
                      subtitle: 'Mua từ đối tác · thanh toán trên trang của họ',
                    ),
                  ),
                  if (data.affiliate.isEmpty)
                    SliverToBoxAdapter(
                      child: _SectionEmpty(message: 'Chưa có sản phẩm bổ trợ', onRetry: cubit.refresh),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => MarketplaceAffiliateCard(
                          product: data.affiliate[i],
                          onTap: () => _onAffiliateTap(context, data.affiliate[i]),
                        ),
                        childCount: data.affiliate.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Icon(Icons.eco_outlined, size: 36, color: MarketplaceTheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: MarketplaceTheme.textMuted)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: MarketplaceTheme.primary),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
