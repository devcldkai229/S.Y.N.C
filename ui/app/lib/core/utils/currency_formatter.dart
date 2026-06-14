import 'package:intl/intl.dart';

/// Định dạng tiền Việt Nam: phân cách hàng nghìn bằng dấu chấm (185.000đ).
abstract final class CurrencyFormatter {
  static final NumberFormat _viWhole = NumberFormat.decimalPattern('vi_VN');

  /// Số tiền không kèm đơn vị, ví dụ `185.000`.
  static String formatAmount(num amount) => _viWhole.format(amount.round());

  /// VND đầy đủ, ví dụ `185.000đ`.
  static String formatVnd(num amount) => '${formatAmount(amount)}đ';

  /// Theo loại tiền — VND/đ dùng chuẩn Việt Nam.
  static String formatMoney(num amount, {String? currency}) {
    final code = (currency ?? 'VND').trim().toUpperCase();
    if (code == 'VND' || code == 'Đ' || code == 'D') {
      return formatVnd(amount);
    }
    return '${formatAmount(amount)} $currency';
  }
}
