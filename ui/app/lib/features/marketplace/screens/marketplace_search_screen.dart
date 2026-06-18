import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/data/marketplace_catalog.dart';
import 'package:sync_app/features/marketplace/data/marketplace_repository.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/models/marketplace_listing_filter.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/marketplace/services/marketplace_location_service.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';
import 'package:sync_app/features/marketplace/widgets/marketplace_network_image.dart';
import 'package:sync_app/features/order/data/checkout_remote_data_source.dart';
import 'package:sync_app/shared/widgets/sync_shimmer_box.dart';

class MarketplaceSearchScreen extends StatefulWidget {
  const MarketplaceSearchScreen({super.key});

  @override
  State<MarketplaceSearchScreen> createState() => _MarketplaceSearchScreenState();
}

class _MarketplaceSearchScreenState extends State<MarketplaceSearchScreen> {
  final _repo = getIt<MarketplaceRepository>();
  final _controller = TextEditingController();
  MarketplaceSearchResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _controller.text.trim();
    if (q.length < 2) {
      setState(() {
        _result = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    _search(q);
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

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final delivery = await _delivery();
      final result = await _repo.search(
        query: query,
        lat: delivery?.lat,
        lng: delivery?.lng,
      );
      if (mounted) setState(() => _result = result);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tìm được kết quả');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final hasQuery = _controller.text.trim().length >= 2;

    return Scaffold(
      backgroundColor: MarketplaceTheme.background,
      appBar: AppBar(
        backgroundColor: MarketplaceTheme.background,
        elevation: 0,
        foregroundColor: MarketplaceTheme.heading,
        title: const Text('Tìm kiếm', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Hôm nay ăn gì healthy?',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: MarketplaceTheme.border),
                ),
              ),
            ),
          ),
          Expanded(child: _buildResults(result, hasQuery)),
        ],
      ),
    );
  }

  Widget _buildResults(MarketplaceSearchResult? result, bool hasQuery) {
    if (!hasQuery) {
      return const Center(
        child: Text(
          'Gõ tên quán hoặc món để tìm',
          style: TextStyle(color: MarketplaceTheme.textMuted),
        ),
      );
    }
    if (_loading) {
      return ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SyncShimmerBox(height: 56),
        ),
      );
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: MarketplaceTheme.textMuted)));
    }
    if (result == null || (result.partners.isEmpty && result.dishes.isEmpty)) {
      return const Center(
        child: Text('Không có kết quả', style: TextStyle(color: MarketplaceTheme.textMuted)),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (result.partners.isNotEmpty) ...[
          const _SectionTitle('Quán'),
          ...result.partners.map(
            (p) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.storefront_rounded)),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: p.distanceKm != null
                  ? Text(MarketplaceFormatters.formatKm(p.distanceKm))
                  : null,
              onTap: () => context.push(AppRoutes.marketplacePartner(p.id)),
            ),
          ),
        ],
        if (result.dishes.isNotEmpty) ...[
          const _SectionTitle('Món ăn'),
          ...result.dishes.map((d) => _DishTile(dish: d)),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }
}

class _DishTile extends StatelessWidget {
  const _DishTile({required this.dish});

  final FoodMenuItem dish;

  @override
  Widget build(BuildContext context) {
    final image = dish.imageUrls.isNotEmpty ? dish.imageUrls.first : null;
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: image != null
            ? MarketplaceNetworkImage(
                imageUrl: image,
                assetFallback: MarketplaceCatalog.dishPlaceholder,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              )
            : Container(
                width: 48,
                height: 48,
                color: MarketplaceTheme.lightGreen,
                child: const Icon(Icons.restaurant_rounded, color: MarketplaceTheme.primary),
              ),
      ),
      title: Text(dish.nameVi, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${dish.nutrition.calories} kcal · ${MarketplaceFormatters.formatVnd(dish.price)}',
      ),
      onTap: () => context.push(AppRoutes.marketplaceFoodItem(dish.id)),
    );
  }
}
