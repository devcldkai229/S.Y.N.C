import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/subscription/models/subscription_models.dart';
import 'package:sync_app/features/subscription/services/subscription_api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with WidgetsBindingObserver {
  final _api = getIt<SubscriptionApiService>();

  List<SubscriptionPlan> _plans = [];
  ActiveSubscription? _activeSub;
  bool _loading = true;
  String? _error;

  final _couponController = TextEditingController();
  int? _pendingOrderCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _couponController.dispose();
    super.dispose();
  }

  // Poll trạng thái giao dịch khi user quay lại app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingOrderCode != null) {
      _pollTransaction(_pendingOrderCode!);
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getPlans(),
        _api.getActiveSubscription(),
      ]);
      if (!mounted) return;
      setState(() {
        _plans     = (results[0] as List<SubscriptionPlan>).where((p) => !p.isFree).toList();
        _activeSub = results[1] as ActiveSubscription?;
        _loading   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );
    try {
      final coupon = _couponController.text.trim();
      final link   = await _api.createPaymentLink(plan.id, couponCode: coupon.isEmpty ? null : coupon);
      if (!mounted) return;
      Navigator.of(context).pop();

      setState(() { _pendingOrderCode = link.orderCode; });

      final uri = Uri.parse(link.checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        _showSnack('Không thể mở trang thanh toán.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _pollTransaction(int orderCode) async {
    for (var i = 0; i < 12; i++) {
      await Future.delayed(const Duration(seconds: 4));
      try {
        final tx = await _api.getTransactionStatus(orderCode);
        if (tx?.status == 'Succeeded') {
          setState(() { _pendingOrderCode = null; });
          await _load();
          if (!mounted) return;
          _showSnack('Đã nâng cấp lên Premium!');
          return;
        }
        if (tx?.status == 'Failed' || tx?.status == 'Cancelled') {
          setState(() { _pendingOrderCode = null; });
          _showSnack('Giao dịch không thành công.', isError: true);
          return;
        }
      } catch (_) { /* Bỏ qua lỗi mạng, tiếp tục poll */ }
    }
    // Hết timeout — dừng poll, giữ nút kiểm tra
  }

  Future<void> _cancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Huỷ gói Premium'),
        content: const Text(
          'Bạn sẽ giữ quyền Premium tới ngày hết hạn. Sau đó tài khoản về gói Free.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Huỷ gói', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.cancelSubscription();
      await _load();
      if (!mounted) return;
      _showSnack('Đã huỷ gia hạn. Gói vẫn còn hiệu lực tới ngày hết hạn.');
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : AppColors.primaryGreen,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
        ),
        title: const Text(
          'Subscription',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: AppColors.primaryGreen,
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      const _Header(),
                      const SizedBox(height: 20),

                      // Hiển thị gói đang dùng nếu có
                      if (_activeSub != null) ...[
                        _ActiveSubCard(
                          sub: _activeSub!,
                          onCancel: _activeSub!.status == 'Active' ? _cancelSubscription : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Banner poll đang chờ xác nhận
                      if (_pendingOrderCode != null) ...[
                        _PendingPaymentBanner(
                          onCheck: () => _pollTransaction(_pendingOrderCode!),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Ô nhập mã khuyến mãi
                      _CouponField(controller: _couponController),
                      const SizedBox(height: 16),

                      // Free plan
                      const _FreePlanCard(),
                      const SizedBox(height: 14),

                      // Paid plans từ backend
                      ..._plans.map(
                        (plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _PaidPlanCard(
                            plan: plan,
                            isCurrentPlan: _activeSub != null,
                            onSubscribe: _activeSub != null ? null : () => _subscribe(plan),
                          ),
                        ),
                      ),

                      if (_plans.isEmpty && _activeSub == null)
                        _DefaultPremiumCard(onSubscribe: null),
                    ],
                  ),
                ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade400, Colors.orange.shade600],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nâng cấp lên Premium',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mở khóa toàn bộ tính năng của SyncPlatform',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }
}

// ─── Active sub card ─────────────────────────────────────────────────────────

class _ActiveSubCard extends StatelessWidget {
  const _ActiveSubCard({required this.sub, this.onCancel});

  final ActiveSubscription sub;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final expiry = sub.expiredAt;
    final label  = sub.status == 'Cancelled' ? 'Đã huỷ (hết hạn ' : 'Hết hạn ';
    final expiryStr = expiry != null
        ? '$label${expiry.day}/${expiry.month}/${expiry.year})'
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: AppColors.primaryGreen, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gói ${sub.subscriptionPlanName} đang hoạt động',
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                  ),
                ),
                if (expiryStr.isNotEmpty)
                  Text(expiryStr,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: const Text('Huỷ', style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

// ─── Pending payment banner ───────────────────────────────────────────────────

class _PendingPaymentBanner extends StatelessWidget {
  const _PendingPaymentBanner({required this.onCheck});

  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_outlined, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Đang chờ xác nhận thanh toán...',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: onCheck,
            child: const Text('Kiểm tra', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Coupon field ─────────────────────────────────────────────────────────────

class _CouponField extends StatelessWidget {
  const _CouponField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        hintText: 'Mã khuyến mãi (tuỳ chọn)',
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.local_offer_outlined, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}

// ─── Free plan card ───────────────────────────────────────────────────────────

class _FreePlanCard extends StatelessWidget {
  const _FreePlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('FREE', AppColors.lightGreen, AppColors.primaryGreen),
          const SizedBox(height: 12),
          const Text('0 đ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const Text('mãi mãi', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          ...[
            'Truy cập bài tập cơ bản',
            'Theo dõi streak & thành tích',
            'Mạng xã hội cộng đồng',
          ].map((f) => _FeatureRow(text: f, included: true, muted: true)),
        ],
      ),
    );
  }
}

// ─── Paid plan card ───────────────────────────────────────────────────────────

class _PaidPlanCard extends StatelessWidget {
  const _PaidPlanCard({
    required this.plan,
    required this.isCurrentPlan,
    required this.onSubscribe,
  });

  final SubscriptionPlan plan;
  final bool isCurrentPlan;
  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    final features = plan.features.isNotEmpty
        ? plan.features
        : _buildDefaultFeatures(plan);

    return _PremiumCardShell(
      priceLabel: '${_fmt(plan.monthlyPrice)} đ',
      period: '/tháng',
      features: features,
      isCurrentPlan: isCurrentPlan,
      onSubscribe: onSubscribe,
    );
  }

  List<String> _buildDefaultFeatures(SubscriptionPlan p) => [
    'Tất cả tính năng Free',
    'Thông báo AI cá nhân hóa',
    if (p.premiumWorkoutAccess) 'Bài tập nâng cao & video HD',
    if (p.priorityAiResponses)  'AI phản hồi ưu tiên',
    if (p.aiUsageLimitPerMonth == 0) 'AI không giới hạn',
  ];
}

// ─── Default premium card (fallback khi backend chưa seed) ───────────────────

class _DefaultPremiumCard extends StatelessWidget {
  const _DefaultPremiumCard({required this.onSubscribe});

  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    return _PremiumCardShell(
      priceLabel: '99.000 đ',
      period: '/tháng',
      features: const [
        'Tất cả tính năng Free',
        'Thông báo AI cá nhân hóa',
        'AI phản hồi ưu tiên',
      ],
      isCurrentPlan: false,
      onSubscribe: onSubscribe,
    );
  }
}

// ─── Premium card shell ───────────────────────────────────────────────────────

class _PremiumCardShell extends StatelessWidget {
  const _PremiumCardShell({
    required this.priceLabel,
    required this.period,
    required this.features,
    required this.isCurrentPlan,
    required this.onSubscribe,
  });

  final String priceLabel;
  final String period;
  final List<String> features;
  final bool isCurrentPlan;
  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: AppColors.primaryGreen.withValues(alpha: 0.35),
          blurRadius: 18, offset: const Offset(0, 8),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge('PREMIUM', Colors.white.withValues(alpha: 0.25), Colors.white),
              const Spacer(),
              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 14),
          Text(priceLabel,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(period,
              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 18),
          ...features.map((f) => _FeatureRow(text: f, included: true, onDark: true)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSubscribe,
              style: FilledButton.styleFrom(
                backgroundColor: onSubscribe == null ? Colors.white.withValues(alpha: 0.5) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isCurrentPlan ? 'Gói hiện tại' : 'Đăng ký ngay',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800,
                  color: onSubscribe == null ? Colors.white : AppColors.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature row ──────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text, required this.included, this.muted = false, this.onDark = false});

  final String text;
  final bool included;
  final bool muted;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark
        ? Colors.white.withValues(alpha: 0.9)
        : (muted ? AppColors.textSecondary : AppColors.textPrimary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: included ? (onDark ? Colors.white : AppColors.primaryGreen) : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color, height: 1.4))),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _badge(String text, Color bg, Color fg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
  child: Text(text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: fg, letterSpacing: 1)),
);

String _fmt(double price) {
  if (price == 0) return '0';
  return price
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
