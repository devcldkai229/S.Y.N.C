import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_kitchen_card.dart';

class NearbyKitchensScreen extends StatelessWidget {
  const NearbyKitchensScreen({super.key, required this.kitchens});

  final List<KitchenCardVm> kitchens;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarketplaceTheme.background,
      appBar: AppBar(
        backgroundColor: MarketplaceTheme.background,
        elevation: 0,
        foregroundColor: MarketplaceTheme.heading,
        title: const Text('Bếp gần bạn', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: kitchens.isEmpty
          ? const Center(
              child: Text(
                'Chưa có bếp gần đây',
                style: TextStyle(color: MarketplaceTheme.textMuted),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: kitchens.length,
              itemBuilder: (context, index) {
                final kitchen = kitchens[index];
                return MarketplaceKitchenCard(
                  kitchen: kitchen,
                  onTap: () => context.push(AppRoutes.marketplacePartner(kitchen.partner.id)),
                );
              },
            ),
    );
  }
}
