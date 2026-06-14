import 'package:sync_app/core/utils/currency_formatter.dart';

abstract final class MarketplaceFormatters {
  static String formatVnd(num amount) => CurrencyFormatter.formatVnd(amount);

  static String formatMoney(num amount, {String? currency}) =>
      CurrencyFormatter.formatMoney(amount, currency: currency);

  static String formatKm(double? km) {
    if (km == null) return '— km';
    final s = km.toStringAsFixed(1).replaceAll('.', ',');
    return '$s km';
  }

  static String formatRating(double rating, int count) =>
      '${rating.toStringAsFixed(1)} ★ ($count)';
}
