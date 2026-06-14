import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_cart_cubit.dart';
import 'package:sync_app/features/marketplace/data/marketplace_remote_data_source.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_cart_helpers.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';

class PartnerDetailScreen extends StatefulWidget {
  const PartnerDetailScreen({super.key, required this.partnerId});

  final String partnerId;

  @override
  State<PartnerDetailScreen> createState() => _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends State<PartnerDetailScreen> {
  final _api = getIt<MarketplaceRemoteDataSource>();
  PartnerDetail? _partner;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _api.getPartner(widget.partnerId);
      if (mounted) setState(() {
        _partner = p;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<MarketplaceCartCubit>().state;
    final partner = _partner;

    return Scaffold(
      backgroundColor: MarketplaceTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : partner == null
              ? const Center(child: Text('Không tìm thấy bếp'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 180,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(partner.name),
                        background: partner.coverImageUrl != null
                            ? Image.network(partner.coverImageUrl!, fit: BoxFit.cover)
                            : Container(color: MarketplaceTheme.primary.withValues(alpha: 0.2)),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '★ ${partner.ratingAverage} · ${partner.address ?? ''}',
                          style: const TextStyle(color: MarketplaceTheme.textMuted),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = partner.menu[index];
                          return ListTile(
                            title: Text(item.nameVi, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${item.nutrition.calories} kcal · ${MarketplaceFormatters.formatVnd(item.price)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: MarketplaceTheme.primary),
                              onPressed: () async {
                                await marketplaceAddToCart(
                                  context,
                                  item: item,
                                  partnerName: partner.name,
                                );
                              },
                            ),
                            onTap: () => context.push(AppRoutes.marketplaceFoodItem(item.id)),
                          );
                        },
                        childCount: partner.menu.length,
                      ),
                    ),
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
}
