import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_cart_cubit.dart';
import 'package:sync_app/features/marketplace/data/marketplace_remote_data_source.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_cart_helpers.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_partner_hours.dart';
import 'package:sync_app/features/marketplace/widgets/marketplace_asset_image.dart';
import 'package:sync_app/features/order/data/checkout_remote_data_source.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PartnerDetailScreen extends StatefulWidget {
  const PartnerDetailScreen({super.key, required this.partnerId});

  final String partnerId;

  @override
  State<PartnerDetailScreen> createState() => _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends State<PartnerDetailScreen> {
  final _api = getIt<MarketplaceRemoteDataSource>();
  final _checkout = getIt<CheckoutRemoteDataSource>();
  PartnerDetail? _partner;
  double? _distanceKm;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      double? lat;
      double? lng;
      try {
        final saved = await _checkout.getCurrentAddress();
        lat = saved?.lat;
        lng = saved?.lng;
      } catch (_) {}

      final p = await _api.getPartner(widget.partnerId, lat: lat, lng: lng);
      final distance = p.distanceKm ??
          MarketplacePartnerHours.distanceKm(
            deliveryLat: lat,
            deliveryLng: lng,
            partnerLocation: p.location,
          );

      if (mounted) {
        setState(() {
          _partner = p;
          _distanceKm = distance;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, List<FoodMenuItem>> _groupedMenu(List<FoodMenuItem> menu) {
    final map = <String, List<FoodMenuItem>>{};
    for (final item in menu) {
      final key = _categoryLabel(item.category);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  static String _categoryLabel(String category) {
    return switch (category) {
      'PreparedMeal' => 'Món chính',
      'Beverage' => 'Đồ uống',
      'Vegetable' => 'Salad & rau',
      'Snack' => 'Ăn vặt',
      'Protein' => 'Protein',
      'Grains' => 'Tinh bột',
      _ => category.isEmpty ? 'Khác' : category,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<MarketplaceCartCubit>().state;
    final partner = _partner;

    return Scaffold(
      backgroundColor: MarketplaceTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MarketplaceTheme.primary))
          : partner == null
              ? const Center(child: Text('Không tìm thấy bếp'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(partner.name, style: const TextStyle(fontSize: 16)),
                        background: partner.coverImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: partner.coverImageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(color: MarketplaceTheme.primary.withValues(alpha: 0.2)),
                      ),
                    ),
                    SliverToBoxAdapter(child: _PartnerHeader(partner: partner, distanceKm: _distanceKm)),
                    ..._menuSlivers(partner),
                    const SliverToBoxAdapter(child: SizedBox(height: 90)),
                  ],
                ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: () => context.push(AppRoutes.orderCart),
                  style: FilledButton.styleFrom(backgroundColor: MarketplaceTheme.primary),
                  child: Text(
                    '${cart.itemCount} món · ${MarketplaceFormatters.formatVnd(cart.subtotal)} · Xem giỏ',
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _menuSlivers(PartnerDetail partner) {
    final grouped = _groupedMenu(partner.menu);
    final slivers = <Widget>[];
    for (final entry in grouped.entries) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              entry.key,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = entry.value[index];
              return _MenuItemTile(
                item: item,
                partnerName: partner.name,
                onTap: () => context.push(AppRoutes.marketplaceFoodItem(item.id)),
                onAdd: () => marketplaceAddToCart(
                  context,
                  item: item,
                  partnerName: partner.name,
                ),
              );
            },
            childCount: entry.value.length,
          ),
        ),
      );
    }
    return slivers;
  }
}

class _PartnerHeader extends StatelessWidget {
  const _PartnerHeader({required this.partner, this.distanceKm});

  final PartnerDetail partner;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final isOpen = partner.isOpenNow;
    final hours = MarketplacePartnerHours.todayHoursLabel(partner.operatingHours);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? MarketplaceTheme.lightGreen : Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOpen ? 'Đang mở' : 'Đã đóng',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isOpen ? MarketplaceTheme.primary : Colors.white70,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(hours, style: const TextStyle(fontSize: 12, color: MarketplaceTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${MarketplaceFormatters.formatRating(partner.ratingAverage, partner.ratingCount)}'
            '${distanceKm != null ? ' · ${MarketplaceFormatters.formatKm(distanceKm)}' : ''}',
            style: const TextStyle(color: MarketplaceTheme.textMuted),
          ),
          if (partner.address != null && partner.address!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(partner.address!, style: const TextStyle(color: MarketplaceTheme.textMuted, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.item,
    required this.partnerName,
    required this.onTap,
    required this.onAdd,
  });

  final FoodMenuItem item;
  final String partnerName;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final image = item.imageUrls.isNotEmpty ? item.imageUrls.first : null;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: image != null
            ? CachedNetworkImage(imageUrl: image, width: 56, height: 56, fit: BoxFit.cover)
            : const MarketplaceAssetImage(
                assetPath: 'assets/marketplace/placeholders/dish_placeholder.png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
      ),
      title: Text(item.nameVi, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        '${item.nutrition.calories} kcal · ${MarketplaceFormatters.formatVnd(item.price)}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: MarketplaceTheme.primary),
        onPressed: onAdd,
      ),
      onTap: onTap,
    );
  }
}
