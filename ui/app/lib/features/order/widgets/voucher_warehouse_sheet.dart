import 'package:flutter/material.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';
import 'package:sync_app/features/order/data/payment_remote_data_source.dart';
import 'package:sync_app/features/order/models/checkout_models.dart';

class VoucherWarehouseSheet extends StatefulWidget {
  const VoucherWarehouseSheet({
    super.key,
    required this.paymentApi,
    required this.orderAmount,
    this.partnerId,
    this.initialCode,
  });

  final PaymentRemoteDataSource paymentApi;
  final double orderAmount;
  final String? partnerId;
  final String? initialCode;

  static Future<VoucherValidation?> show(
    BuildContext context, {
    required PaymentRemoteDataSource paymentApi,
    required double orderAmount,
    String? partnerId,
    String? initialCode,
  }) {
    return showModalBottomSheet<VoucherValidation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: MarketplaceTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: VoucherWarehouseSheet(
          paymentApi: paymentApi,
          orderAmount: orderAmount,
          partnerId: partnerId,
          initialCode: initialCode,
        ),
      ),
    );
  }

  @override
  State<VoucherWarehouseSheet> createState() => _VoucherWarehouseSheetState();
}

class _VoucherWarehouseSheetState extends State<VoucherWarehouseSheet> {
  final _search = TextEditingController();
  List<VoucherItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) _search.text = widget.initialCode!;
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.paymentApi.getAvailableVouchers(
        orderAmount: widget.orderAmount,
        partnerId: widget.partnerId,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được kho voucher';
        _loading = false;
      });
    }
  }

  Future<void> _applyCode(String code) async {
    try {
      final result = await widget.paymentApi.validateVoucher(
        code: code,
        orderAmount: widget.orderAmount,
        partnerId: widget.partnerId,
      );
      if (!mounted) return;
      if (result.valid) {
        Navigator.pop(context, result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Voucher không hợp lệ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Kho Voucher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: const InputDecoration(hintText: 'Nhập mã voucher'),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _applyCode(_search.text.trim()),
                  style: FilledButton.styleFrom(backgroundColor: MarketplaceTheme.primary),
                  child: const Text('Áp dụng'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, textAlign: TextAlign.center)
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final v = _items[i];
                    return Opacity(
                      opacity: v.eligible ? 1 : 0.55,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: MarketplaceTheme.cardDecoration(),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.code, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text(v.title, style: const TextStyle(fontSize: 13)),
                                  Text(
                                    'Giảm ${MarketplaceFormatters.formatVnd(v.estimatedDiscount)} · Tối thiểu ${MarketplaceFormatters.formatVnd(v.minOrderAmount)}',
                                    style: const TextStyle(fontSize: 12, color: MarketplaceTheme.textMuted),
                                  ),
                                  if (!v.eligible && v.ineligibleReason != null)
                                    Text(
                                      v.ineligibleReason!,
                                      style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                                    ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: v.eligible ? () => _applyCode(v.code) : null,
                              child: const Text('Áp dụng'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
