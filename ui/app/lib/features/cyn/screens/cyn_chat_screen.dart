import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/context_navigation.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/cyn/models/cyn_chat_models.dart';
import 'package:sync_app/features/cyn/state/cyn_chat_session_store.dart';
import 'package:sync_app/features/cyn/widgets/cyn_insight_charts.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/widgets/home/marketplace_location_picker_sheet.dart';
import 'package:sync_app/features/marketplace/widgets/marketplace_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

/// SYNC accent green for user chat bubbles (#DEFF9A).
const _cynAccentGreen = Color(0xFFDEFF9A);

class CynChatScreen extends StatefulWidget {
  const CynChatScreen({super.key, this.initialMessage});

  final String? initialMessage;

  @override
  State<CynChatScreen> createState() => _CynChatScreenState();
}

class _CynChatScreenState extends State<CynChatScreen> with TickerProviderStateMixin {
  final _store = getIt<CynChatSessionStore>();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isMuted = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const _greeting =
      'Chào bạn! Mình là CYN — coach AI của SYNC. Hỏi mình về lịch tập, dinh dưỡng hoặc gợi ý bữa ăn nhé.';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    _store.ensureSeeded(_greeting);
    // Voice shell is gated (P2); always start in text chat.
    _store.endVoiceMode();
    _store.addListener(_onStoreChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      _store.sendInitialIfNeeded(widget.initialMessage);
    });
  }

  void _onStoreChanged() {
    if (!mounted) return;
    final hint = _store.snackbarHint;
    if (hint != null && hint.isNotEmpty) {
      _store.clearSnackbarHint();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hint), behavior: SnackBarBehavior.floating),
        );
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToBottom(jump: _store.isStreaming);
    });
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool jump = false}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (jump) {
      _scrollController.jumpTo(target);
      return;
    }
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _showVoiceComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice AI đang phát triển, vui lòng quay lại sau.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleMode() {
    // Continuous voice (STT/TTS) is not wired yet — do not enter fake listening UI.
    _showVoiceComingSoon();
  }

  Future<void> _onSendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _store.isStreaming) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
    await _store.send(text);
  }

  void _onMicUnavailable() => _showVoiceComingSoon();

  Future<void> _confirmPending(CynChatMessage message, {required bool confirmed}) async {
    try {
      await _store.confirmPending(message, confirmed: confirmed);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xác nhận được: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final isVoiceMode = _store.isVoiceMode;
        final isDark = isVoiceMode;
        final isStreaming = _store.isStreaming;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0B0F14) : AppColors.background,
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: !isVoiceMode,
          body: Column(
            children: [
              _CynChatAppBar(
                topPadding: topPadding,
                isDark: isDark,
                isVoiceMode: isVoiceMode,
                isStreaming: isStreaming,
                onBack: () => context.popOrGoHome(),
                onToggleMode: _toggleMode,
              ),
              if (!isVoiceMode) const _CynMedicalDisclaimerBanner(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: isVoiceMode
                      ? _VoiceConversationBody(
                          key: const ValueKey('voice'),
                          pulseAnimation: _pulseAnimation,
                          isMuted: _isMuted,
                          onToggleMute: () => setState(() => _isMuted = !_isMuted),
                          onEndCall: _store.endVoiceMode,
                        )
                      : _MessagingBody(
                          key: const ValueKey('messaging'),
                          scrollController: _scrollController,
                          messages: _store.messages,
                          isConfirming: _store.isConfirming,
                          onConfirmPending: _confirmPending,
                          onRequestLocation: () => _store.requestLocationFromUi(),
                          onPaymentMethodSelected: (method) {
                            final label = switch (method) {
                              'wallet' => 'Tôi chọn thanh toán bằng Sync Wallet',
                              'cod' => 'Tôi chọn thanh toán COD khi nhận hàng',
                              'vietqr' => 'Tôi chọn thanh toán VietQR',
                              _ => 'Tôi chọn phương thức $method',
                            };
                            _store.send(label);
                          },
                          onDeliveryInfoSubmitted: (data) {
                            final name = (data['name'] ?? '').toString().trim();
                            final phone = (data['phone'] ?? '').toString().trim();
                            final address = (data['address'] ?? '').toString().trim();
                            final payment = (data['payment_method'] ?? '')
                                .toString()
                                .trim()
                                .toLowerCase();
                            final lat = data['lat'];
                            final lng = data['lng'];
                            final bits = <String>[
                              if (name.isNotEmpty) 'Tên: $name',
                              if (phone.isNotEmpty) 'SĐT: $phone',
                              if (address.isNotEmpty) 'Địa chỉ: $address',
                            ];
                            final payLabel = switch (payment) {
                              'wallet' => 'Sync Wallet',
                              'cod' => 'COD khi nhận hàng',
                              'vietqr' => 'VietQR',
                              _ => '',
                            };
                            final payBit = payLabel.isEmpty
                                ? ''
                                : ' Phương thức thanh toán: $payLabel.';
                            // Toạ độ đi qua kênh structured (latitude/longitude) —
                            // không in lat/lng trong bubble chat.
                            _store.send(
                              'Thông tin giao hàng: ${bits.join('; ')}.$payBit '
                              'Xác nhận đặt đơn với delivery_confirmed=true.',
                              latitude: lat is num ? lat.toDouble() : null,
                              longitude: lng is num ? lng.toDouble() : null,
                            );
                          },
                          onPremiumUpsell: () {
                            if (AppConfig.requiresPlayBillingForPremium) {
                              context.push(AppRoutes.subscription);
                              return;
                            }
                            _store.send(
                              'Mình muốn nâng cấp Premium để mở AI Insights và biểu đồ.',
                            );
                          },
                        ),
                ),
              ),
              if (!isVoiceMode)
                _FrostedInputBar(
                  controller: _textController,
                  isRecording: false,
                  isBusy: isStreaming,
                  onSend: _onSendText,
                  onRecordStart: _onMicUnavailable,
                  onRecordEnd: () {},
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CynChatAppBar extends StatelessWidget {
  const _CynChatAppBar({
    required this.topPadding,
    required this.isDark,
    required this.isVoiceMode,
    required this.isStreaming,
    required this.onBack,
    required this.onToggleMode,
  });

  final double topPadding;
  final bool isDark;
  final bool isVoiceMode;
  final bool isStreaming;
  final VoidCallback onBack;
  final VoidCallback onToggleMode;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.white : AppColors.textPrimary;
    final muted = isDark ? Colors.white70 : AppColors.textMuted;

    return Container(
      padding: EdgeInsets.fromLTRB(4, topPadding + 4, 8, 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : AppColors.cardBackground.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: fg),
            tooltip: 'Quay lại',
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                          : [AppColors.lightGreen, _cynAccentGreen.withValues(alpha: 0.55)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.white : AppColors.primaryGreen).withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: isDark ? _cynAccentGreen : AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CYN AI Coach',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: fg,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.brightGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isStreaming ? 'Đang trả lời...' : 'Online',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleMode,
            tooltip: 'Voice AI (đang phát triển)',
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.backgroundAlt,
            ),
            icon: Icon(
              isVoiceMode ? Icons.chat_bubble_outline_rounded : Icons.graphic_eq_rounded,
              color: isVoiceMode ? _cynAccentGreen : fg,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _CynMedicalDisclaimerBanner extends StatefulWidget {
  const _CynMedicalDisclaimerBanner();

  @override
  State<_CynMedicalDisclaimerBanner> createState() => _CynMedicalDisclaimerBannerState();
}

class _CynMedicalDisclaimerBannerState extends State<_CynMedicalDisclaimerBanner> {
  static const _prefsKey = 'cyn_medical_disclaimer_acked';
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPreferences>();
    _visible = prefs.getBool(_prefsKey) != true;
  }

  Future<void> _dismiss() async {
    await getIt<SharedPreferences>().setBool(_prefsKey, true);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFFFFF8E7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFB45309)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'CYN là trợ lý fitness/dinh dưỡng, không phải bác sĩ — không chẩn đoán hay kê đơn. '
                'Với chấn thương hoặc triệu chứng bất thường, hãy gặp chuyên gia y tế.',
                style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF78350F)),
              ),
            ),
            IconButton(
              onPressed: _dismiss,
              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF78350F)),
              tooltip: 'Đã hiểu',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagingBody extends StatelessWidget {
  const _MessagingBody({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.isConfirming,
    required this.onConfirmPending,
    required this.onRequestLocation,
    required this.onPaymentMethodSelected,
    this.onDeliveryInfoSubmitted,
    this.onPremiumUpsell,
  });

  final ScrollController scrollController;
  final List<CynChatMessage> messages;
  final bool isConfirming;
  final void Function(CynChatMessage message, {required bool confirmed}) onConfirmPending;
  final VoidCallback onRequestLocation;
  final void Function(String method) onPaymentMethodSelected;
  final void Function(Map<String, dynamic> data)? onDeliveryInfoSubmitted;
  final VoidCallback? onPremiumUpsell;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        switch (msg.role) {
          case CynMessageRole.cyn:
            return _CynBubble(
              messageId: msg.id,
              text: msg.text,
              time: msg.time,
              isStreaming: msg.isStreaming,
              error: msg.error,
              handoffLabel: msg.handoffLabel,
              pendingAction: msg.pendingAction,
              displayPayloads: msg.displayPayloads,
              isConfirming: isConfirming,
              onConfirm: msg.pendingAction != null
                  ? (confirmed) => onConfirmPending(msg, confirmed: confirmed)
                  : null,
              onRequestLocation: onRequestLocation,
              onPaymentMethodSelected: onPaymentMethodSelected,
              onDeliveryInfoSubmitted: onDeliveryInfoSubmitted,
              onPremiumUpsell: onPremiumUpsell,
            );
          case CynMessageRole.system:
            return _SystemBubble(text: msg.text, time: msg.time);
          case CynMessageRole.user:
            return _UserBubble(
              text: msg.text,
              time: msg.time,
              read: msg.read,
            );
        }
      },
    );
  }
}

class _CynBubble extends StatelessWidget {
  const _CynBubble({
    required this.messageId,
    required this.text,
    this.time,
    this.isStreaming = false,
    this.error = false,
    this.handoffLabel,
    this.pendingAction,
    this.displayPayloads = const [],
    this.isConfirming = false,
    this.onConfirm,
    this.onRequestLocation,
    this.onPaymentMethodSelected,
    this.onDeliveryInfoSubmitted,
    this.onPremiumUpsell,
  });

  final String messageId;
  final String text;
  final String? time;
  final bool isStreaming;
  final bool error;
  final String? handoffLabel;
  final Map<String, dynamic>? pendingAction;
  final List<Map<String, dynamic>> displayPayloads;
  final bool isConfirming;
  final void Function(bool confirmed)? onConfirm;
  final VoidCallback? onRequestLocation;
  final void Function(String method)? onPaymentMethodSelected;
  final void Function(Map<String, dynamic> data)? onDeliveryInfoSubmitted;
  final VoidCallback? onPremiumUpsell;

  Future<void> _reportAiContent(BuildContext context) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        const reasons = [
          'Nội dung không phù hợp',
          'Tư vấn y khoa nguy hiểm',
          'Spam / lừa đảo',
          'Khác',
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Báo cáo nội dung AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...reasons.map(
                  (r) => ListTile(
                    title: Text(r),
                    onTap: () => Navigator.pop(ctx, r),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (reason == null || !context.mounted) return;
    try {
      final targetId = _stableGuidFromString(messageId);
      await getIt<SocialRepository>().reportAiContent(
        targetId: targetId,
        reason: reason,
        details: text.length > 500 ? '${text.substring(0, 500)}…' : text,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi báo cáo. Cảm ơn bạn.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không gửi được báo cáo: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Deterministic UUID-ish Guid string from local message id (for AiContent target).
  static String _stableGuidFromString(String raw) {
    final bytes = utf8.encode(raw);
    var h1 = 0x811c9dc5;
    var h2 = 0x01000193;
    for (final b in bytes) {
      h1 = ((h1 ^ b) * 0x01000193) & 0xffffffff;
      h2 = ((h2 ^ (b << 1)) * 0x811c9dc5) & 0xffffffff;
    }
    final a = h1.toRadixString(16).padLeft(8, '0');
    final b = (h2 & 0xffff).toRadixString(16).padLeft(4, '0');
    final c = ((h2 >> 16) & 0x0fff | 0x4000).toRadixString(16).padLeft(4, '0');
    final d = (0x8000 | (h1 & 0x3fff)).toRadixString(16).padLeft(4, '0');
    final e = ((h1 ^ h2) & 0xffffffff).toRadixString(16).padLeft(8, '0') +
        ((h1 + h2) & 0xffff).toRadixString(16).padLeft(4, '0');
    return '$a-$b-$c-$d-${e.substring(0, 12)}';
  }

  @override
  Widget build(BuildContext context) {
    final showTyping = isStreaming && text.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primaryGreen),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (handoffLabel != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      handoffLabel!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
                GestureDetector(
                  onLongPress: isStreaming || text.isEmpty
                      ? null
                      : () => _reportAiContent(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: error ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                      ),
                      border: error ? Border.all(color: Colors.red.shade200) : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: showTyping
                        ? const _TypingDots()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StreamingText(
                                text: text,
                                isStreaming: isStreaming,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: error ? Colors.red.shade800 : AppColors.textPrimary,
                                ),
                              ),
                              if (!isStreaming && text.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    onTap: () => _reportAiContent(context),
                                    child: Text(
                                      'Báo cáo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
                if (pendingAction != null && onConfirm != null) ...[
                  const SizedBox(height: 8),
                  _PendingActionCard(
                    action: pendingAction!,
                    isConfirming: isConfirming,
                    onConfirm: onConfirm!,
                  ),
                ],
                if (displayPayloads.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._mergeCheckoutDisplayPayloads(displayPayloads).map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _DisplayPayloadCard(
                        payload: p,
                        onRequestLocation: onRequestLocation,
                        onPaymentMethodSelected: onPaymentMethodSelected,
                        onDeliveryInfoSubmitted: onDeliveryInfoSubmitted,
                        onPremiumUpsell: onPremiumUpsell,
                      ),
                    ),
                  ),
                ],
                if (time != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(time!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemBubble extends StatelessWidget {
  const _SystemBubble({required this.text, this.time});

  final String text;
  final String? time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// Merge legacy `delivery_info_form` + `payment_method_select` into one
/// `checkout_form` so payment radios submit with delivery fields.
List<Map<String, dynamic>> _mergeCheckoutDisplayPayloads(
  List<Map<String, dynamic>> payloads,
) {
  Map<String, dynamic>? delivery;
  Map<String, dynamic>? payment;
  final others = <Map<String, dynamic>>[];
  for (final p in payloads) {
    final type = p['type']?.toString() ?? '';
    if (type == 'delivery_info_form' && delivery == null) {
      delivery = p;
    } else if (type == 'payment_method_select' && payment == null) {
      payment = p;
    } else {
      others.add(p);
    }
  }
  if (delivery != null && payment != null) {
    return [
      {
        'type': 'checkout_form',
        'prefill': delivery['prefill'] ?? const {},
        'fields': delivery['fields'] ?? const [],
        'walletBalance': payment['walletBalance'],
        'walletBalanceLabel': payment['walletBalanceLabel'],
        'walletSufficient': payment['walletSufficient'],
        'amount': payment['amount'],
        'options': payment['options'] ?? const ['wallet', 'cod', 'vietqr'],
      },
      ...others,
    ];
  }
  if (delivery != null) others.insert(0, delivery);
  if (payment != null) others.add(payment);
  return others;
}

class _DisplayPayloadCard extends StatelessWidget {
  const _DisplayPayloadCard({
    required this.payload,
    this.onRequestLocation,
    this.onPaymentMethodSelected,
    this.onDeliveryInfoSubmitted,
    this.onPremiumUpsell,
  });

  final Map<String, dynamic> payload;
  final VoidCallback? onRequestLocation;
  final void Function(String method)? onPaymentMethodSelected;
  final void Function(Map<String, dynamic> data)? onDeliveryInfoSubmitted;
  final VoidCallback? onPremiumUpsell;

  @override
  Widget build(BuildContext context) {
    final type = payload['type']?.toString() ?? '';
    if (type == 'premium_upsell') {
      return CynPremiumUpsellCard(
        payload: payload,
        onUpgrade: onPremiumUpsell ??
            () {
              if (AppConfig.requiresPlayBillingForPremium) {
                context.push(AppRoutes.subscription);
              }
            },
      );
    }
    if (type == 'play_billing_cta') {
      return _ctaCard(
        title: 'Nâng cấp Premium',
        body:
            'Trên Android, Premium thanh toán qua Google Play (không dùng VietQR trong app).',
        buttonLabel: 'Xem gói Premium',
        onPressed: () => context.push(AppRoutes.subscription),
      );
    }
    if (type == 'chart' || type == 'insight_dashboard') {
      return CynInsightChartCard(payload: payload);
    }
    if (type == 'adjustment_plan') {
      return _AdjustmentPlanCard(payload: payload);
    }
    if (type == 'weekly_report') {
      return CynWeeklyReportCard(payload: payload);
    }
    if (type == 'request_location_permission') {
      final reason = payload['reason']?.toString() ??
          'Cho phép vị trí để tìm quán gần bạn';
      return _ctaCard(
        title: 'Cho phép vị trí',
        body: reason,
        buttonLabel: 'Cho phép truy cập vị trí',
        onPressed: () async {
          final serviceOn = await Geolocator.isLocationServiceEnabled();
          if (!serviceOn) {
            await Geolocator.openLocationSettings();
          }
          onRequestLocation?.call();
        },
      );
    }
    if (type == 'payment_qr') {
      final purpose = payload['purpose']?.toString() ?? '';
      final url = payload['checkoutUrl']?.toString() ?? '';
      final amount = payload['amount'];
      final isPremiumUpgrade = purpose == 'premium_upgrade';

      // Android Play: do not open VietQR for digital Premium.
      if (isPremiumUpgrade && AppConfig.requiresPlayBillingForPremium) {
        return _ctaCard(
          title: 'Nâng cấp Premium',
          body:
              'Trên Android, Premium thanh toán qua Google Play (không dùng VietQR trong app).',
          buttonLabel: 'Xem gói Premium',
          onPressed: () => context.push(AppRoutes.subscription),
        );
      }

      final title = isPremiumUpgrade
          ? 'Thanh toán Premium'
          : 'Thanh toán VietQR';
      final amountLabel = amount is num ? '${amount.toStringAsFixed(0)}đ' : null;
      return _ctaCard(
        title: title,
        body: amountLabel != null
            ? 'Số tiền: $amountLabel. Mở link để quét VietQR.'
            : 'Mở link VietQR để hoàn tất thanh toán.',
        buttonLabel: isPremiumUpgrade
            ? 'Thanh toán Premium'
            : 'Mở VietQR',
        onPressed: url.isEmpty
            ? null
            : () async {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
      );
    }
    if (type == 'order_success') {
      final orderId = payload['orderId']?.toString() ?? '';
      final amount = payload['amount'];
      final method = payload['paymentMethod']?.toString() ?? '';
      final amountLabel =
          amount is num ? '${amount.toStringAsFixed(0)}đ' : null;
      final bodyParts = <String>[
        if (orderId.isNotEmpty) 'Mã đơn: $orderId',
        if (amountLabel != null) 'Tổng: $amountLabel',
        if (method.isNotEmpty) 'Thanh toán: $method',
      ];
      return _ctaCard(
        title: 'Đặt đơn thành công',
        body: bodyParts.isEmpty
            ? 'Đơn đã được tạo. Xem trong danh sách đơn hàng.'
            : bodyParts.join('\n'),
        buttonLabel: 'Xem đơn hàng',
        onPressed: () {
          if (orderId.isNotEmpty) {
            context.push(AppRoutes.orderDetail(orderId));
          } else {
            context.push(AppRoutes.orderList);
          }
        },
      );
    }
    if (type == 'payment_method_select') {
      // Standalone payment (delivery already confirmed): radios + one confirm.
      return _PaymentMethodRadioCard(
        payload: payload,
        onSelected: onPaymentMethodSelected,
      );
    }
    if (type == 'exercise_media') {
      final name = (payload['exerciseName'] ?? payload['name'] ?? 'Bài tập').toString();
      final imagesRaw = payload['images'];
      final images = <String>[];
      if (imagesRaw is List) {
        for (final u in imagesRaw) {
          if (u is String && u.trim().isNotEmpty) images.add(u.trim());
        }
      }
      if (images.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length.clamp(0, 8),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: MarketplaceNetworkImage(
                      imageUrl: images[i],
                      width: 160,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    if (type == 'food_detail' || type == 'partner_detail') {
      final dataRaw = payload['data'];
      final data = dataRaw is Map
          ? Map<String, dynamic>.from(dataRaw)
          : Map<String, dynamic>.from(payload);
      return _detailCard(type: type, data: data);
    }
    if (type == 'cart') {
      return _cartCard(payload);
    }
    if (type == 'delivery_info_form' || type == 'checkout_form') {
      return _CheckoutFormCard(
        payload: payload,
        includePayment: type == 'checkout_form' ||
            (payload['options'] is List) ||
            ((payload['fields'] as List?)
                    ?.any((f) => f is Map && f['key'] == 'payment_method') ??
                false),
        onSubmitted: onDeliveryInfoSubmitted,
      );
    }
    if (type == 'partner_list' ||
        type == 'dish_list' ||
        type == 'menu_list' ||
        type == 'review_list') {
      final items = payload['items'];
      if (items is! List || items.isEmpty) return const SizedBox.shrink();
      final heading = switch (type) {
        'partner_list' => 'Quán gợi ý',
        'dish_list' || 'menu_list' => 'Món gợi ý',
        'review_list' => 'Review',
        _ => 'Kết quả',
      };
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...items.take(8).whereType<Map>().map((raw) {
              final m = Map<String, dynamic>.from(raw);
              return _listItemRow(type: type, item: m);
            }),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _listItemRow({required String type, required Map<String, dynamic> item}) {
    if (type == 'review_list') {
      final comment = (item['comment'] ?? item['Comment'] ?? 'Review').toString();
      final rating = item['rating'] ?? item['Rating'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          rating != null ? '★$rating · $comment' : comment,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }
    final name = (item['nameVi'] ??
            item['NameVi'] ??
            item['name'] ??
            item['Name'] ??
            'Mục')
        .toString();
    final partnerName = (item['partnerName'] ?? item['PartnerName'] ?? '').toString().trim();
    final rating =
        item['ratingAverage'] ?? item['RatingAverage'] ?? item['rating'] ?? item['Rating'];
    final price = item['price'] ?? item['Price'];
    final imageUrl = _imageOf(item);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: MarketplaceNetworkImage(
              imageUrl: imageUrl,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
                if (partnerName.isNotEmpty &&
                    (type == 'dish_list' || type == 'menu_list'))
                  Text(
                    partnerName,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                if (rating != null || price != null)
                  Text(
                    [
                      if (rating != null) '★$rating',
                      if (price != null) '$priceđ',
                    ].join(' · '),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartCard(Map<String, dynamic> payload) {
    final items = payload['items'];
    final total = payload['total'];
    if (items is! List || items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: const Text(
          'Giỏ hàng trống',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giỏ hàng',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...items.take(12).whereType<Map>().map((raw) {
            final m = Map<String, dynamic>.from(raw);
            final name = (m['name'] ?? m['Name'] ?? m['foodId'] ?? 'Món').toString();
            final qty = m['qty'] ?? m['quantity'] ?? 1;
            final price = m['unitPrice'] ?? m['unit_price'] ?? m['price'];
            final line = price is num
                ? '$name × $qty · ${price.toStringAsFixed(0)}đ'
                : '$name × $qty';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            );
          }),
          if (total is num) ...[
            const SizedBox(height: 6),
            Text(
              'Tạm tính: ${total.toStringAsFixed(0)}đ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailCard({required String type, required Map<String, dynamic> data}) {
    final isFood = type == 'food_detail';
    final title = (data['nameVi'] ??
            data['NameVi'] ??
            data['name'] ??
            data['Name'] ??
            (isFood ? 'Chi tiết món' : 'Chi tiết quán'))
        .toString();
    final partnerName = (data['partnerName'] ?? data['PartnerName'] ?? '').toString().trim();
    final imageUrl = _imageOf(data);
    final price = data['price'] ?? data['Price'];
    final rating =
        data['ratingAverage'] ?? data['RatingAverage'] ?? data['rating'] ?? data['Rating'];
    final calories = data['calories'] ?? data['Calories'] ?? data['calo'];
    final protein = data['proteinG'] ?? data['ProteinG'] ?? data['protein'];
    final carbs = data['carbG'] ?? data['CarbG'] ?? data['carbohydrate'];
    final fat = data['fatG'] ?? data['FatG'] ?? data['fat'];
    final address = data['address'] ?? data['Address'];
    final desc = (data['description'] ?? data['Description'] ?? '').toString();

    final lines = <String>[];
    if (isFood && partnerName.isNotEmpty) lines.add('Quán: $partnerName');
    if (price != null) lines.add('Giá: $priceđ');
    if (rating != null) lines.add('★ $rating');
    if (calories != null) lines.add('$calories kcal');
    if (protein != null || carbs != null || fat != null) {
      lines.add(
        'P ${protein ?? '-'}g · C ${carbs ?? '-'}g · F ${fat ?? '-'}g',
      );
    }
    if (address != null) lines.add(address.toString());
    if (desc.isNotEmpty) lines.add(desc);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: MarketplaceNetworkImage(
              imageUrl: imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                ...lines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      l,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _imageOf(Map<String, dynamic> m) {
    final direct = m['imageUrl'] ?? m['ImageUrl'] ?? m['coverImageUrl'] ?? m['CoverImageUrl'];
    if (direct != null && direct.toString().isNotEmpty) return direct.toString();
    final urls = m['imageUrls'] ?? m['ImageUrls'];
    if (urls is List && urls.isNotEmpty) return urls.first.toString();
    return null;
  }

  Widget _ctaCard({
    required String title,
    required String body,
    required String buttonLabel,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutFormCard extends StatefulWidget {
  const _CheckoutFormCard({
    required this.payload,
    required this.includePayment,
    this.onSubmitted,
  });

  final Map<String, dynamic> payload;
  final bool includePayment;
  final void Function(Map<String, dynamic> data)? onSubmitted;

  @override
  State<_CheckoutFormCard> createState() => _CheckoutFormCardState();
}

class _CheckoutFormCardState extends State<_CheckoutFormCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  double? _lat;
  double? _lng;
  bool _submitting = false;
  String? _paymentMethod;

  @override
  void initState() {
    super.initState();
    final prefill = widget.payload['prefill'];
    final map = prefill is Map ? Map<String, dynamic>.from(prefill) : <String, dynamic>{};
    _nameCtrl = TextEditingController(text: (map['name'] ?? map['fullName'] ?? '').toString());
    _phoneCtrl = TextEditingController(text: (map['phone'] ?? '').toString());
    _addressCtrl = TextEditingController(text: (map['address'] ?? '').toString());
    final lat = map['lat'];
    final lng = map['lng'];
    if (lat is num) _lat = lat.toDouble();
    if (lng is num) _lng = lng.toDouble();

    // Default COD for food delivery; user can switch to Wallet/VietQR.
    if (widget.includePayment) {
      _paymentMethod = 'cod';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAddress() async {
    DeliveryLocation? initial;
    final address = _addressCtrl.text.trim();
    if (_lat != null && _lng != null) {
      initial = DeliveryLocation(
        lat: _lat!,
        lng: _lng!,
        shortLabel: address.isEmpty ? 'Vị trí đã chọn' : address,
        fullAddress: address.isEmpty ? 'Vị trí đã chọn' : address,
      );
    }
    final picked = await MarketplaceLocationPickerScreen.show(
      context,
      initial: initial,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _addressCtrl.text = picked.fullAddress;
      _lat = picked.lat;
      _lng = picked.lng;
    });
  }

  void _submit() {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập họ tên, SĐT và địa chỉ giao hàng.')),
      );
      return;
    }
    if (widget.includePayment && (_paymentMethod == null || _paymentMethod!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn phương thức thanh toán.')),
      );
      return;
    }
    final walletOk = widget.payload['walletSufficient'] != false;
    if (_paymentMethod == 'wallet' && !walletOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ví không đủ số dư — chọn COD hoặc VietQR.')),
      );
      return;
    }
    setState(() => _submitting = true);
    widget.onSubmitted?.call({
      'name': name,
      'phone': phone,
      'address': address,
      'lat': _lat,
      'lng': _lng,
      if (widget.includePayment) 'payment_method': _paymentMethod,
    });
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.payload['amount'];
    final balance = widget.payload['walletBalance'];
    final walletSufficient = widget.payload['walletSufficient'];
    final amountLabel =
        amount is num ? 'Giá trị đơn: ${amount.toStringAsFixed(0)}đ' : '';
    var balanceLabel = balance is num
        ? 'Số dư ví: ${balance.toStringAsFixed(0)}đ'
        : (widget.payload['walletBalanceLabel']?.toString() ?? '');
    if (balanceLabel.isNotEmpty && walletSufficient is bool) {
      if (walletSufficient) {
        balanceLabel = '$balanceLabel — Đủ thanh toán đơn này';
      } else if (balance is num && amount is num) {
        balanceLabel =
            '$balanceLabel — Thiếu ${(amount - balance).toStringAsFixed(0)}đ';
      } else {
        balanceLabel = '$balanceLabel — Không đủ cho đơn này';
      }
    }
    final walletDisabled = walletSufficient == false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.includePayment ? 'Xác nhận đặt hàng' : 'Thông tin giao hàng',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Họ tên',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại',
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressCtrl,
            readOnly: true,
            onTap: _pickAddress,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ giao',
              isDense: true,
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.map_outlined),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _pickAddress,
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: const Text('Chọn trên bản đồ'),
          ),
          if (widget.includePayment) ...[
            const SizedBox(height: 12),
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (amountLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                amountLabel,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
            if (balanceLabel.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                balanceLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: walletDisabled ? Colors.red.shade700 : AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 4),
            RadioGroup<String>(
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v),
              child: Column(
                children: [
                  RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: 'wallet',
                    enabled: !walletDisabled,
                    title: Text(
                      walletDisabled
                          ? 'Sync Wallet (thiếu số dư)'
                          : 'Sync Wallet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: walletDisabled
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: 'cod',
                    title: Text(
                      'COD (thanh toán khi nhận hàng)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: 'vietqr',
                    title: Text(
                      'VietQR (chuyển khoản)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _submitting
                    ? 'Đã gửi'
                    : (widget.includePayment
                        ? 'Xác nhận đặt hàng'
                        : 'Xác nhận thông tin'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodRadioCard extends StatefulWidget {
  const _PaymentMethodRadioCard({
    required this.payload,
    this.onSelected,
  });

  final Map<String, dynamic> payload;
  final void Function(String method)? onSelected;

  @override
  State<_PaymentMethodRadioCard> createState() => _PaymentMethodRadioCardState();
}

class _PaymentMethodRadioCardState extends State<_PaymentMethodRadioCard> {
  String? _method;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _method = 'cod';
  }

  void _confirm() {
    if (_submitting || _method == null) return;
    final walletOk = widget.payload['walletSufficient'] != false;
    if (_method == 'wallet' && !walletOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ví không đủ số dư — chọn COD hoặc VietQR.')),
      );
      return;
    }
    setState(() => _submitting = true);
    widget.onSelected?.call(_method!);
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.payload['walletBalance'];
    final amount = widget.payload['amount'];
    final sufficientRaw = widget.payload['walletSufficient'];
    final bool? walletSufficient = sufficientRaw is bool
        ? sufficientRaw
        : (balance is num && amount is num ? balance >= amount : null);
    var balanceLabel = balance is num
        ? 'Số dư ví: ${balance.toStringAsFixed(0)}đ'
        : (widget.payload['walletBalanceLabel']?.toString() ?? '');
    if (balanceLabel.isNotEmpty && walletSufficient != null) {
      if (walletSufficient) {
        balanceLabel = '$balanceLabel — Đủ thanh toán đơn này';
      } else if (balance is num && amount is num) {
        balanceLabel =
            '$balanceLabel — Thiếu ${(amount - balance).toStringAsFixed(0)}đ';
      } else {
        balanceLabel = '$balanceLabel — Không đủ cho đơn này';
      }
    }
    final amountLabel =
        amount is num ? 'Giá trị đơn: ${amount.toStringAsFixed(0)}đ' : '';
    final walletDisabled = walletSufficient == false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn phương thức thanh toán',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (amountLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              amountLabel,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          if (balanceLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              balanceLabel,
              style: TextStyle(
                fontSize: 12,
                color: walletDisabled ? Colors.red.shade700 : AppColors.textMuted,
              ),
            ),
          ],
          RadioGroup<String>(
            groupValue: _method,
            onChanged: (v) => setState(() => _method = v),
            child: Column(
              children: [
                RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: 'wallet',
                  enabled: !walletDisabled,
                  title: Text(
                    walletDisabled ? 'Sync Wallet (thiếu số dư)' : 'Sync Wallet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: walletDisabled
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: 'cod',
                  title: Text(
                    'COD (thanh toán khi nhận hàng)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: 'vietqr',
                  title: Text(
                    'VietQR (chuyển khoản)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(_submitting ? 'Đã gửi' : 'Xác nhận thanh toán'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card Adaptive Engine: so sánh mục tiêu CŨ → MỚI + lý do + độ tin cậy.
class _AdjustmentPlanCard extends StatelessWidget {
  const _AdjustmentPlanCard({required this.payload});

  final Map<String, dynamic> payload;

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : const {};

  String _fmt(dynamic v) {
    if (v == null) return '—';
    if (v is num) return v.round().toString();
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final old = _asMap(payload['old']);
    final neu = _asMap(payload['new']);
    final confidence = payload['confidence']?.toString() ?? '';
    final autoApplied = payload['autoApplied'] == true;
    final etaWeeks = payload['etaWeeks'];
    final reasonsRaw = payload['reasons'];
    final reasons = reasonsRaw is List
        ? reasonsRaw.map((e) => e.toString()).take(3).toList()
        : const <String>[];

    Widget row(String label, dynamic oldV, dynamic newV, String unit) {
      final changed = _fmt(oldV) != _fmt(newV);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textMuted)),
            ),
            Text('${_fmt(oldV)}$unit',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  decoration: changed ? TextDecoration.lineThrough : null,
                )),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward,
                  size: 12, color: AppColors.textMuted),
            ),
            Text('${_fmt(newV)}$unit',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                )),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high,
                  size: 16, color: AppColors.primaryGreen),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Điều chỉnh mục tiêu (Adaptive)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ),
              if (autoApplied)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Đã áp dụng',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.primaryGreen)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          row('Calo', old['calories'], neu['calories'], ' kcal'),
          row('Đạm', old['protein_g'], neu['protein_g'], 'g'),
          row('Tinh bột', old['carb_g'], neu['carb_g'], 'g'),
          row('Béo', old['fat_g'], neu['fat_g'], 'g'),
          if (etaWeeks is num) ...[
            const SizedBox(height: 4),
            Text('Dự kiến đạt mục tiêu sau ~${etaWeeks.toStringAsFixed(1)} tuần',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('• $r',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.3)),
                )),
          ],
          if (confidence.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Độ tin cậy: $confidence',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _PendingActionCard extends StatelessWidget {
  const _PendingActionCard({
    required this.action,
    required this.onConfirm,
    this.isConfirming = false,
  });

  final Map<String, dynamic> action;
  final void Function(bool confirmed) onConfirm;
  final bool isConfirming;

  @override
  Widget build(BuildContext context) {
    final summary = action['summary']?.toString();
    final planSummary = action['plan_summary']?.toString();
    final amount = action['amount'];
    final amountLabel = amount is num ? '${amount.toStringAsFixed(0)}đ' : null;
    final type = action['type']?.toString() ?? '';
    final title = switch (type) {
      'upgrade_premium' => 'Nâng cấp Premium',
      'enable_ai_reschedule' => 'Cho phép AI chỉnh lịch tập',
      'plan_or_edit_workout' || 'generate_week_plan' => 'Xác nhận lịch tập',
      'apply_adjustment' => 'Xác nhận điều chỉnh mục tiêu',
      'create_roadmap' || 'delete_roadmap' || 'reschedule_session' =>
        'Xác nhận lộ trình',
      'log_meal' => 'Xác nhận nhật ký bữa ăn',
      'create_order' => 'Xác nhận đặt đơn',
      'pay_with_wallet' || 'create_payment_link' || 'topup_wallet' =>
        'Xác nhận thanh toán',
      '' => 'Xác nhận',
      _ => 'Xác nhận',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          if (summary != null && summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(summary, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
          if (planSummary != null && planSummary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(planSummary, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ],
          if (amountLabel != null) ...[
            const SizedBox(height: 4),
            Text(amountLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryGreen)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isConfirming ? null : () => onConfirm(false),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: isConfirming ? null : () => onConfirm(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: isConfirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Xác nhận'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreamingText extends StatefulWidget {
  const _StreamingText({
    required this.text,
    required this.isStreaming,
    required this.style,
  });

  final String text;
  final bool isStreaming;
  final TextStyle style;

  @override
  State<_StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<_StreamingText> with SingleTickerProviderStateMixin {
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isStreaming) {
      return Text(widget.text, style: widget.style);
    }

    return AnimatedBuilder(
      animation: _cursorController,
      builder: (context, child) {
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(text: widget.text, style: widget.style),
              TextSpan(
                text: '▍',
                style: widget.style.copyWith(
                  color: AppColors.primaryGreen.withValues(alpha: 0.35 + _cursorController.value * 0.65),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final phase = (_controller.value + i * 0.2) % 1.0;
              final scale = 0.6 + (phase < 0.5 ? phase : 1 - phase) * 0.8;
              return Container(
                width: 7,
                height: 7,
                margin: EdgeInsets.only(right: i == 2 ? 0 : 5),
                transform: Matrix4.diagonal3Values(scale, scale, 1),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.35 + scale * 0.45),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text, this.time, this.read = false});

  final String text;
  final String? time;
  final bool read;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _cynAccentGreen,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: _cynAccentGreen.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (time != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                if (read) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all_rounded,
                    size: 14,
                    color: AppColors.primaryGreen.withValues(alpha: 0.85),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FrostedInputBar extends StatelessWidget {
  const _FrostedInputBar({
    required this.controller,
    required this.isRecording,
    required this.isBusy,
    required this.onSend,
    required this.onRecordStart,
    required this.onRecordEnd,
  });

  final TextEditingController controller;
  final bool isRecording;
  final bool isBusy;
  final VoidCallback onSend;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordEnd;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 10, 12, bottom + 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: 0.82),
            border: const Border(top: BorderSide(color: AppColors.borderLight)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundAlt,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: controller,
                    enabled: !isBusy,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: isBusy ? null : (_) => onSend(),
                    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Hỏi CYN về lịch tập...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onLongPressStart: (_) => onRecordStart(),
                onLongPressEnd: (_) => onRecordEnd(),
                onTap: onRecordStart,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isRecording ? Colors.red.shade400 : AppColors.backgroundAlt,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRecording ? Colors.red.shade300 : AppColors.borderLight,
                    ),
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: isRecording ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filled(
                onPressed: isBusy ? null : onSend,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primaryGreen.withValues(alpha: 0.45),
                ),
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceConversationBody extends StatelessWidget {
  const _VoiceConversationBody({
    super.key,
    required this.pulseAnimation,
    required this.isMuted,
    required this.onToggleMute,
    required this.onEndCall,
  });

  final Animation<double> pulseAnimation;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF0B0F14),
            Color(0xFF050608),
          ],
        ),
      ),
      child: Column(
        children: [
          const Spacer(flex: 2),
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              final scale = 0.92 + pulseAnimation.value * 0.14;
              final glow = 0.25 + pulseAnimation.value * 0.35;
              return SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _PulseRing(size: 200, opacity: glow * 0.35, color: _cynAccentGreen),
                    _PulseRing(size: 160, opacity: glow * 0.55, color: _cynAccentGreen),
                    _PulseRing(size: 120, opacity: glow * 0.75, color: AppColors.brightGreen),
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [_cynAccentGreen, Color(0xFF22C55E), Color(0xFF14532D)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _cynAccentGreen.withValues(alpha: glow),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.graphic_eq_rounded,
                          color: Color(0xFF0B0F14),
                          size: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'CYN đang lắng nghe...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nói tự nhiên — CYN sẽ phản hồi ngay',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const Spacer(flex: 3),
          Padding(
            padding: EdgeInsets.fromLTRB(32, 0, 32, bottom + 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _VoiceControlButton(
                  icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: isMuted ? 'Bật mic' : 'Tắt mic',
                  onTap: onToggleMute,
                  isSecondary: true,
                ),
                GestureDetector(
                  onTap: onEndCall,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 72),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.size,
    required this.opacity,
    required this.color,
  });

  final double size;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: opacity), width: 2),
      ),
    );
  }
}

class _VoiceControlButton extends StatelessWidget {
  const _VoiceControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSecondary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.1),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}
