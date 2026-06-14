import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/features/marketplace/data/marketplace_catalog.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/widgets/marketplace_asset_image.dart';

/// Promo slides above "Gợi ý cho bạn".
class MarketplacePromoCarousel extends StatefulWidget {
  const MarketplacePromoCarousel({super.key});

  @override
  State<MarketplacePromoCarousel> createState() => _MarketplacePromoCarouselState();
}

class MarketplacePromoSlide {
  const MarketplacePromoSlide({this.assetPath, this.networkImageUrl, this.label});

  final String? assetPath;
  final String? networkImageUrl;
  final String? label;
}

abstract final class MarketplacePromoSlides {
  static const items = [
    MarketplacePromoSlide(assetPath: MarketplaceCatalog.promoBanner1),
    MarketplacePromoSlide(assetPath: MarketplaceCatalog.promoBanner2),
    MarketplacePromoSlide(assetPath: MarketplaceCatalog.promoBanner3),
  ];
}

class _MarketplacePromoCarouselState extends State<MarketplacePromoCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 32;
    final height = width * 9 / 20;
    final slides = MarketplacePromoSlides.items;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          CarouselSlider.builder(
            itemCount: slides.length,
            options: CarouselOptions(
              height: height,
              viewportFraction: 1,
              autoPlay: slides.length > 1,
              autoPlayInterval: const Duration(seconds: 5),
              onPageChanged: (i, _) => setState(() => _index = i),
            ),
            itemBuilder: (context, index, _) {
              final slide = slides[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: slide.assetPath != null
                      ? MarketplaceAssetImage(
                          assetPath: slide.assetPath!,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                          label: slide.label,
                        )
                      : slide.networkImageUrl != null
                          ? Image.network(
                              slide.networkImageUrl!,
                              width: width,
                              height: height,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _promoFallback(slide),
                            )
                          : _promoFallback(slide),
                ),
              );
            },
          ),
          if (slides.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (i) => Container(
                  width: i == _index ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _index
                        ? MarketplaceTheme.primary
                        : MarketplaceTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _promoFallback(MarketplacePromoSlide slide) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MarketplaceTheme.primary.withValues(alpha: 0.85),
            MarketplaceTheme.primary.withValues(alpha: 0.55),
          ],
        ),
        border: Border.all(color: MarketplaceTheme.border),
      ),
      alignment: Alignment.center,
      child: Text(
        slide.label ?? 'SYNC Foods',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
