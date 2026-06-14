import 'package:flutter/material.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/data/marketplace_remote_data_source.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_cart_helpers.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/widgets/rating_stars.dart';

class FoodMenuItemDetailScreen extends StatefulWidget {
  const FoodMenuItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<FoodMenuItemDetailScreen> createState() => _FoodMenuItemDetailScreenState();
}

class _FoodMenuItemDetailScreenState extends State<FoodMenuItemDetailScreen> {
  final _api = getIt<MarketplaceRemoteDataSource>();
  FoodMenuItem? _item;
  String? _partnerName;
  bool _failed = false;
  int _qty = 1;
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final item = await _api.getFoodMenuItem(widget.itemId);
      if (!mounted) return;
      setState(() {
        _item = item;
        _partnerName = null;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    if (_failed) {
      return Scaffold(
        appBar: AppBar(backgroundColor: MarketplaceTheme.background),
        body: const Center(child: Text('Không tải được món ăn')),
      );
    }
    if (item == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: MarketplaceTheme.background,
      appBar: AppBar(backgroundColor: MarketplaceTheme.background, title: Text(item.nameVi)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 200,
            decoration: MarketplaceTheme.cardDecoration(),
            child: item.imageUrls.isNotEmpty
                ? Image.network(item.imageUrls.first, fit: BoxFit.cover)
                : const Icon(Icons.restaurant, size: 64, color: MarketplaceTheme.primary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(label: Text('${item.nutrition.calories} kcal')),
              const SizedBox(width: 8),
              Text(
                MarketplaceFormatters.formatMoney(item.price, currency: item.currency),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: item.dietaryTags.map((t) => Chip(label: Text(t))).toList(),
          ),
          const SizedBox(height: 12),
          Text(item.description),
          const SizedBox(height: 12),
          RatingStars(rating: item.ratingAverage),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _qty = (_qty - 1).clamp(1, 99)), icon: const Icon(Icons.remove)),
              Text('$_qty', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              IconButton(onPressed: () => setState(() => _qty++), icon: const Icon(Icons.add)),
            ],
          ),
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Ghi chú (vd: ít cay)')),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () async {
              final ok = await marketplaceAddToCart(
                context,
                item: item,
                partnerName: _partnerName ?? 'Bếp',
                quantity: _qty,
                notes: _notes.text.isEmpty ? null : _notes.text,
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: MarketplaceTheme.primary),
            child: const Text('Thêm vào giỏ'),
          ),
        ),
      ),
    );
  }
}
