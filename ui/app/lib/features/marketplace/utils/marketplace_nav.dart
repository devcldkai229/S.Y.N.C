import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_home_cubit.dart';
import 'package:sync_app/features/marketplace/data/marketplace_catalog.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/models/marketplace_listing_filter.dart';
import 'package:sync_app/features/marketplace/services/marketplace_location_service.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_location_picker_sheet.dart';
import 'package:sync_app/features/order/data/checkout_remote_data_source.dart';

abstract final class MarketplaceNav {
  static Future<DeliveryLocation?> ensureDeliveryLocation(BuildContext context) async {
    final checkout = getIt<CheckoutRemoteDataSource>();
    try {
      final saved = await checkout.getCurrentAddress();
      if (saved != null) {
        final delivery = DeliveryLocation(
          lat: saved.lat,
          lng: saved.lng,
          shortLabel: MarketplaceLocationService.shortenAddress(saved.label),
          fullAddress: saved.label,
        );
        _syncHomeCubit(context, delivery);
        return delivery;
      }
    } catch (_) {}

    DeliveryLocation? initial;
    try {
      initial = context.read<MarketplaceHomeCubit>().state.delivery;
    } catch (_) {}

    final picked = await MarketplaceLocationPickerScreen.show(context, initial: initial);
    if (picked == null) return null;
    if (context.mounted) _syncHomeCubit(context, picked);
    return picked;
  }

  static void _syncHomeCubit(BuildContext context, DeliveryLocation delivery) {
    try {
      context.read<MarketplaceHomeCubit>().setDeliveryLocation(delivery);
    } catch (_) {}
  }

  static Future<void> openListing(
    BuildContext context, {
    required MarketplaceListingFilter filter,
    bool requireLocation = false,
  }) async {
    if (requireLocation || filter.nearbyOnly) {
      final delivery = await ensureDeliveryLocation(context);
      if (delivery == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chọn địa chỉ giao để xem quán gần bạn'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    context.push(AppRoutes.marketplaceListing, extra: filter);
  }

  static void openSearch(BuildContext context) {
    context.push(AppRoutes.marketplaceSearch);
  }

  static void openCategory(BuildContext context, String? categoryId) {
    if (categoryId == null) {
      openListing(context, filter: MarketplaceListingFilter.all);
      return;
    }
    openListing(
      context,
      filter: MarketplaceListingFilter.forCategory(
        categoryId,
        MarketplaceCatalog.labelForCategoryId(categoryId),
      ),
    );
  }

  static void openShortcut(BuildContext context, ShortcutItem shortcut) {
    final tag = shortcut.filterTag;
    if (tag == 'nearby') {
      openListing(context, filter: MarketplaceListingFilter.nearby, requireLocation: true);
      return;
    }
    if (tag == 'macro') {
      openListing(context, filter: MarketplaceListingFilter.macro);
      return;
    }
    if (tag == 'high-protein') {
      openListing(context, filter: MarketplaceListingFilter.highProtein);
      return;
    }
    openListing(context, filter: MarketplaceListingFilter.all);
  }
}
