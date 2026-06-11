import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/subscription/models/subscription_models.dart';
import 'package:sync_app/features/subscription/services/subscription_api_service.dart';
import 'package:sync_app/shared/widgets/app_shell_overlay_scaffold.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _api = getIt<SubscriptionApiService>();

  List<SubscriptionPlan> _plans = [];
  bool _loading = true;
  String? _error;
  bool _yearly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final plans = await _api.getPlans();
      setState(() { _plans = plans; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShellOverlayScaffold(
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                      const SizedBox(height: 24),
                      _BillingToggle(
                        yearly: _yearly,
                        onChanged: (v) => setState(() => _yearly = v),
                      ),
                      const SizedBox(height: 20),
                      const _FreePlanCard(),
                      const SizedBox(height: 14),
                      ..._plans.where((p) => !p.isFree).map(
                        (plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _PaidPlanCard(
                            plan: plan,
                            yearly: _yearly,
                            onSubscribe: () => _subscribe(plan),
                          ),
                        ),
                      ),
                      if (_plans.where((p) => !p.isFree).isEmpty)
                        _DefaultPremiumCard(yearly: _yearly),
                    ],
                  ),
                ),
      ),
    );
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
    );

    try {
      final link = await _api.createPaymentLink(plan.id, yearly: _yearly);
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading

      final uri = Uri.parse(link.checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở trang thanh toán.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade700),
      );
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade400, Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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

// ─── Billing toggle ───────────────────────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.yearly, required this.onChanged});

  final bool yearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Tab(label: 'Theo tháng', selected: !yearly, onTap: () => onChanged(false)),
          _Tab(
            label: 'Theo năm  🎁 -20%',
            selected: yearly,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'FREE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryGreen,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '0 đ',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const Text('mãi mãi', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          ...[
            'Truy cập bài tập cơ bản',
            'AI hỗ trợ 5 lần/tháng',
            'Theo dõi streak & thành tích',
            'Mạng xã hội cộng đồng',
          ].map((f) => _FeatureRow(text: f, included: true, muted: true)),
        ],
      ),
    );
  }
}

// ─── Paid plan card (from backend) ───────────────────────────────────────────

class _PaidPlanCard extends StatelessWidget {
  const _PaidPlanCard({
    required this.plan,
    required this.yearly,
    required this.onSubscribe,
  });

  final SubscriptionPlan plan;
  final bool yearly;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final price = yearly ? plan.yearlyPrice / 12 : plan.monthlyPrice;
    final priceLabel = '${_formatPrice(price)} đ';
    final period = yearly ? '/tháng (thanh toán năm)' : '/tháng';

    final features = plan.features.isNotEmpty
        ? plan.features
        : _defaultPremiumFeatures(plan);

    return _PremiumCardShell(
      priceLabel: priceLabel,
      period: period,
      features: features,
      onSubscribe: onSubscribe,
    );
  }

  List<String> _defaultPremiumFeatures(SubscriptionPlan plan) {
    return [
      'Tất cả tính năng Free',
      if (plan.premiumWorkoutAccess) 'Bài tập nâng cao & video HD',
      if (plan.premiumMarketplaceAccess) 'Marketplace ưu đãi độc quyền',
      if (plan.priorityAiResponses) 'AI phản hồi ưu tiên',
      if (plan.aiUsageLimitPerMonth > 0) 'AI hỗ trợ ${plan.aiUsageLimitPerMonth} lần/tháng',
      'Không giới hạn streak shield',
    ];
  }
}

// ─── Default premium card (khi backend không có plan nào) ────────────────────

class _DefaultPremiumCard extends StatelessWidget {
  const _DefaultPremiumCard({required this.yearly});

  final bool yearly;

  @override
  Widget build(BuildContext context) {
    final price = yearly ? 79167.0 : 99000.0;
    final period = yearly ? '/tháng (thanh toán năm)' : '/tháng';

    return _PremiumCardShell(
      priceLabel: '${_formatPrice(price)} đ',
      period: period,
      features: const [
        'Tất cả tính năng Free',
        'Bài tập nâng cao & video HD',
        'AI hỗ trợ không giới hạn',
        'Marketplace ưu đãi độc quyền',
        'AI phản hồi ưu tiên',
        'Không giới hạn streak shield',
      ],
      onSubscribe: null,
    );
  }
}

class _PremiumCardShell extends StatelessWidget {
  const _PremiumCardShell({
    required this.priceLabel,
    required this.period,
    required this.features,
    required this.onSubscribe,
  });

  final String priceLabel;
  final String period;
  final List<String> features;
  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PREMIUM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            priceLabel,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          Text(period, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 18),
          ...features.map((f) => _FeatureRow(text: f, included: true, onDark: true)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSubscribe,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Đăng ký ngay',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
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
            color: included
                ? (onDark ? Colors.white : AppColors.primaryGreen)
                : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: color, height: 1.4)),
          ),
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
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatPrice(double price) {
  if (price == 0) return '0';
  if (price >= 1000) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
  return price.toStringAsFixed(0);
}
