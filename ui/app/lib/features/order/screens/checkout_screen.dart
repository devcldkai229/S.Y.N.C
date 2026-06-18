import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_cart_cubit.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';
import 'package:sync_app/features/order/data/checkout_remote_data_source.dart';
import 'package:sync_app/features/order/data/order_remote_data_source.dart';
import 'package:sync_app/features/order/data/payment_remote_data_source.dart';
import 'package:sync_app/features/order/models/checkout_models.dart';
import 'package:sync_app/features/order/state/active_order_count_notifier.dart';
import 'package:sync_app/features/order/state/delivery_fee_config.dart';
import 'package:sync_app/features/order/widgets/price_breakdown.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_location_picker_sheet.dart';
import 'package:sync_app/features/order/widgets/voucher_warehouse_sheet.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _orderApi = getIt<OrderRemoteDataSource>();
  final _paymentApi = getIt<PaymentRemoteDataSource>();
  final _checkoutApi = getIt<CheckoutRemoteDataSource>();
  final _deliveryFeeConfig = getIt<DeliveryFeeConfig>();
  final _profileApi = getIt<ProfileApiService>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();

  bool _placing = false;
  double? _lat;
  double? _lng;
  WalletBalance? _wallet;
  CheckoutPaymentMethod _paymentMethod = CheckoutPaymentMethod.wallet;
  VoucherValidation? _appliedVoucher;
  double? _deliveryFee;
  late final String _idempotencyKey;
  bool _nameLockedFromProfile = false;
  bool _phoneLockedFromProfile = false;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = '${DateTime.now().toUtc().millisecondsSinceEpoch}-${identityHashCode(this)}';
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await context.read<MarketplaceCartCubit>().hydrate();
    if (!mounted) return;
    final cart = context.read<MarketplaceCartCubit>().state;
    if (cart.items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giỏ hàng trống')),
        );
        context.pop();
      });
      return;
    }
    await Future.wait([
      _initLocation(),
      _loadWallet(),
      _loadDeliveryFee(),
      _loadRecipientFromProfile(),
    ]);
  }

  Future<void> _loadRecipientFromProfile() async {
    try {
      final settings = await _profileApi.getProfileSettings();
      if (!mounted) return;

      final name = settings.basic.fullName.trim();
      final phone = settings.basic.phoneNumber?.trim();

      setState(() {
        if (name.isNotEmpty) {
          _name.text = name;
          _nameLockedFromProfile = true;
        }
        if (phone != null && phone.isNotEmpty) {
          _phone.text = phone;
          _phoneLockedFromProfile = true;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadDeliveryFee() async {
    try {
      final fee = await _deliveryFeeConfig.load();
      if (mounted) setState(() => _deliveryFee = fee);
    } catch (_) {}
  }

  Future<void> _initLocation() async {
    try {
      final saved = await _checkoutApi.getCurrentAddress();
      if (saved != null && mounted) {
        setState(() {
          _address.text = saved.label;
          _lat = saved.lat;
          _lng = saved.lng;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadWallet() async {
    try {
      final wallet = await _paymentApi.getWalletBalance();
      if (mounted) setState(() => _wallet = wallet);
    } catch (_) {}
  }

  double _preDiscountTotal(MarketplaceCartState cart) => cart.subtotal + (_deliveryFee ?? 0);

  double _discount() => _appliedVoucher?.discountAmount ?? 0;

  double _total(MarketplaceCartState cart) => _preDiscountTotal(cart) - _discount();

  bool _walletInsufficient(MarketplaceCartState cart) {
    final wallet = _wallet;
    if (wallet == null) return false;
    final coinsRequired = wallet.coinsRequiredForVnd(_total(cart));
    return _paymentMethod == CheckoutPaymentMethod.wallet && wallet.coins < coinsRequired;
  }

  Future<void> _openVouchers(MarketplaceCartState cart) async {
    final result = await VoucherWarehouseSheet.show(
      context,
      paymentApi: _paymentApi,
      orderAmount: _preDiscountTotal(cart),
      partnerId: cart.partnerId,
      initialCode: _appliedVoucher?.code,
    );
    if (result != null && mounted) setState(() => _appliedVoucher = result);
  }

  Future<void> _placeOrder() async {
    final cart = context.read<MarketplaceCartCubit>().state;
    if (cart.partnerId == null || cart.items.isEmpty) return;
    if (_address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng')),
      );
      return;
    }
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên và số điện thoại người nhận')),
      );
      return;
    }
    if (_walletInsufficient(cart)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số dư ví không đủ. Vui lòng nạp thêm hoặc chọn phương thức khác.')),
      );
      return;
    }

    setState(() => _placing = true);
    try {
      final result = await _orderApi.placeOrder({
        'partnerId': cart.partnerId,
        'items': cart.items
            .map((item) => {
                  'foodMenuItemId': item.foodMenuItemId,
                  'quantity': item.quantity,
                  if (item.notes != null && item.notes!.isNotEmpty) 'notes': item.notes,
                })
            .toList(),
        'paymentMethod': switch (_paymentMethod) {
          CheckoutPaymentMethod.wallet => 'Wallet',
          CheckoutPaymentMethod.vietqr => 'VietQR',
          CheckoutPaymentMethod.cod => 'COD',
        },
        if (_appliedVoucher?.code != null) 'voucherCode': _appliedVoucher!.code,
        'deliveryAddress': _address.text.trim(),
        'deliveryLat': _lat,
        'deliveryLng': _lng,
        'recipientName': _name.text.trim(),
        'recipientPhone': _phone.text.trim(),
        'notes': _notes.text.trim(),
        'idempotencyKey': _idempotencyKey,
      });

      if (result.requiresExternalPayment) {
        final paid = await _handleVietQrPayment(result);
        if (!paid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chưa nhận được xác nhận thanh toán. Kiểm tra lại trong Đơn hàng.')),
            );
          }
          return;
        }
      }

      if (!mounted) return;
      context.read<MarketplaceCartCubit>().clear();
      await getIt<ActiveOrderCountNotifier>().refresh();
      if (!mounted) return;
      context.go('${AppRoutes.orderSuccess}?toOrders=1', extra: result.order);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 402
                  ? (message ?? 'Số dư ví không đủ')
                  : (message ?? 'Không thể đặt hàng'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<bool> _handleVietQrPayment(PlaceOrderResult result) async {
    if (!mounted) return false;

    final paymentUrl = result.checkoutUrl ?? result.payUrl;
    if (paymentUrl == null || paymentUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không nhận được liên kết thanh toán.')),
      );
      return false;
    }

    final uri = Uri.parse(paymentUrl);
    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở trang thanh toán.')),
      );
      return false;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return false;
    return await showModalBottomSheet<bool>(
          context: context,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          builder: (ctx) => _VietQrPaymentWaitingSheet(
            orderId: result.order.id,
            paymentUrl: paymentUrl,
            orderApi: _orderApi,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<MarketplaceCartCubit>().state;
    final total = _total(cart);
    final walletCoins = _wallet?.coins ?? 0;
    final coinsRequired = _wallet?.coinsRequiredForVnd(total) ?? (total / 100);

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Địa chỉ giao', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () async {
                  await MarketplaceLocationPickerScreen.show(context);
                  await _initLocation();
                },
                child: const Text('Đổi'),
              ),
            ],
          ),
          TextField(
            controller: _address,
            readOnly: true,
            decoration: const InputDecoration(hintText: 'Chưa chọn địa chỉ'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            readOnly: _nameLockedFromProfile,
            decoration: InputDecoration(
              labelText: 'Tên người nhận',
              hintText: _nameLockedFromProfile ? null : 'Nhập tên người nhận',
            ),
          ),
          TextField(
            controller: _phone,
            readOnly: _phoneLockedFromProfile,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Số điện thoại',
              hintText: _phoneLockedFromProfile ? null : 'Nhập số điện thoại',
            ),
          ),
          const SizedBox(height: 20),
          const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _PaymentCard(
            title: 'Ví SYNC',
            subtitle: 'Số dư: ${walletCoins.toStringAsFixed(0)} coin (≈ ${MarketplaceFormatters.formatVnd(walletCoins * 100)})',
            selected: _paymentMethod == CheckoutPaymentMethod.wallet,
            enabled: !_walletInsufficient(cart) || _paymentMethod == CheckoutPaymentMethod.wallet,
            onTap: () => setState(() => _paymentMethod = CheckoutPaymentMethod.wallet),
            trailing: _walletInsufficient(cart)
                ? Text('Cần ${coinsRequired.toStringAsFixed(0)} coin', style: const TextStyle(fontSize: 12, color: Colors.redAccent))
                : null,
          ),
          _PaymentCard(
            title: 'VietQR',
            subtitle: 'Quét mã QR chuyển khoản qua PayOS',
            selected: _paymentMethod == CheckoutPaymentMethod.vietqr,
            onTap: () => setState(() => _paymentMethod = CheckoutPaymentMethod.vietqr),
          ),
          _PaymentCard(
            title: 'COD',
            subtitle: 'Tiền mặt khi nhận hàng',
            selected: _paymentMethod == CheckoutPaymentMethod.cod,
            onTap: () => setState(() => _paymentMethod = CheckoutPaymentMethod.cod),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _openVouchers(cart),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: MarketplaceTheme.cardDecoration(),
              child: Row(
                children: [
                  const Expanded(child: Text('Giảm giá / Voucher', style: TextStyle(fontWeight: FontWeight.w600))),
                  if (_appliedVoucher != null)
                    Chip(
                      label: Text('-${MarketplaceFormatters.formatVnd(_appliedVoucher!.discountAmount)}'),
                      onDeleted: () => setState(() => _appliedVoucher = null),
                    )
                  else
                    const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Ghi chú đơn')),
          const SizedBox(height: 16),
          if (_deliveryFee == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else
            PriceBreakdown(
              subtotal: cart.subtotal,
              deliveryFee: _deliveryFee!,
              discount: _discount(),
              total: total,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _placing || _deliveryFee == null || _walletInsufficient(cart) ? null : _placeOrder,
            style: FilledButton.styleFrom(backgroundColor: MarketplaceTheme.primary),
            child: _placing
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Đặt hàng · ${MarketplaceFormatters.formatVnd(total)}'),
          ),
        ),
      ),
    );
  }
}

class _VietQrPaymentWaitingSheet extends StatefulWidget {
  const _VietQrPaymentWaitingSheet({
    required this.orderId,
    required this.paymentUrl,
    required this.orderApi,
  });

  final String orderId;
  final String paymentUrl;
  final OrderRemoteDataSource orderApi;

  @override
  State<_VietQrPaymentWaitingSheet> createState() => _VietQrPaymentWaitingSheetState();
}

class _VietQrPaymentWaitingSheetState extends State<_VietQrPaymentWaitingSheet> {
  @override
  void initState() {
    super.initState();
    _pollUntilPaid();
  }

  Future<void> _pollUntilPaid() async {
    const attempts = 20;
    for (var i = 0; i < attempts; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      try {
        final order = await widget.orderApi.getOrder(widget.orderId);
        if (order.paymentStatus == 'Paid' || order.status == 'Confirmed') {
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _reopenPaymentPage() async {
    final uri = Uri.parse(widget.paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Đang chờ xác nhận thanh toán...',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hoàn tất thanh toán trên trình duyệt. Giữ màn hình này để hệ thống xác nhận.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _reopenPaymentPage,
            child: const Text('Mở lại trang thanh toán'),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? MarketplaceTheme.primary : const Color(0xFFE5E7EB),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selected ? MarketplaceTheme.primary : MarketplaceTheme.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: MarketplaceTheme.textMuted)),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
