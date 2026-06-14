import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/data/marketplace_repository.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/models/marketplace_listing_filter.dart';
import 'package:sync_app/features/marketplace/services/marketplace_location_service.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_nav.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_home_skeleton.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_kitchen_card.dart';
import 'package:sync_app/features/order/data/checkout_remote_data_source.dart';

class MarketplaceListingScreen extends StatefulWidget {
  const MarketplaceListingScreen({super.key, required this.filter});

  final MarketplaceListingFilter filter;

  @override
  State<MarketplaceListingScreen> createState() => _MarketplaceListingScreenState();
}

class _MarketplaceListingScreenState extends State<MarketplaceListingScreen> {
  final _repo = getIt<MarketplaceRepository>();
  List<KitchenCardVm> _kitchens = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<DeliveryLocation?> _delivery() async {
    try {
      final saved = await getIt<CheckoutRemoteDataSource>().getCurrentAddress();
      if (saved == null) return null;
      return DeliveryLocation(
        lat: saved.lat,
        lng: saved.lng,
        shortLabel: MarketplaceLocationService.shortenAddress(saved.label),
        fullAddress: saved.label,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final delivery = await _delivery();
      final kitchens = await _repo.loadListing(
        filter: widget.filter,
        lat: delivery?.lat,
        lng: delivery?.lng,
      );
      if (mounted) setState(() => _kitchens = kitchens);
    } catch (e) {
      if (mounted) setState(() => _error = 'Không tải được danh sách quán');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarketplaceTheme.background,
      appBar: AppBar(
        backgroundColor: MarketplaceTheme.background,
        elevation: 0,
        foregroundColor: MarketplaceTheme.heading,
        title: Text(widget.filter.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        color: MarketplaceTheme.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [MarketplaceHomeSkeleton()],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: const TextStyle(color: MarketplaceTheme.textMuted)),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _load,
                    style: FilledButton.styleFrom(backgroundColor: MarketplaceTheme.primary),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_kitchens.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront_outlined, size: 48, color: MarketplaceTheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có quán phù hợp khu vực này',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: MarketplaceTheme.textMuted),
                ),
                if (widget.filter.nearbyOnly) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => MarketplaceNav.ensureDeliveryLocation(context),
                    child: const Text('Chọn địa chỉ giao'),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: _kitchens.length,
      itemBuilder: (context, index) {
        final kitchen = _kitchens[index];
        return MarketplaceKitchenCard(
          kitchen: kitchen,
          onTap: () => context.push(AppRoutes.marketplacePartner(kitchen.partner.id)),
        );
      },
    );
  }
}
