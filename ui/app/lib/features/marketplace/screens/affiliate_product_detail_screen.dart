import 'package:flutter/material.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/data/marketplace_remote_data_source.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class AffiliateProductDetailScreen extends StatefulWidget {
  const AffiliateProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<AffiliateProductDetailScreen> createState() => _AffiliateProductDetailScreenState();
}

class _AffiliateProductDetailScreenState extends State<AffiliateProductDetailScreen> {
  final _api = getIt<MarketplaceRemoteDataSource>();
  AffiliateProduct? _product;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _api.getAffiliateProduct(widget.productId);
    if (mounted) setState(() => _product = p);
  }

  Future<void> _buy() async {
    final url = await _api.trackAffiliateClick(widget.productId);
    final uri = Uri.parse(url.isNotEmpty ? url : _product!.affiliateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;
    if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text(p.nameVi)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.brandName, style: const TextStyle(color: MarketplaceTheme.textMuted)),
            Text(p.nameVi, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${p.price.toStringAsFixed(0)} ${p.currency}'),
            const SizedBox(height: 12),
            Text(p.description),
            const Spacer(),
            Text(
              'Bạn sẽ được chuyển đến ${p.brandName} để hoàn tất mua hàng.',
              style: const TextStyle(fontSize: 13, color: MarketplaceTheme.textMuted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _buy,
                style: FilledButton.styleFrom(backgroundColor: MarketplaceTheme.primary),
                child: Text('Mua tại ${p.brandName}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
