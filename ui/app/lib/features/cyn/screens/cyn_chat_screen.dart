import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/context_navigation.dart';

/// SYNC accent green for user chat bubbles (#DEFF9A).
const _cynAccentGreen = Color(0xFFDEFF9A);

enum CynChatMode { messaging, voiceConversation }

class CynChatScreen extends StatefulWidget {
  const CynChatScreen({super.key});

  @override
  State<CynChatScreen> createState() => _CynChatScreenState();
}

class _CynChatScreenState extends State<CynChatScreen> with TickerProviderStateMixin {
  static const _dummyMessages = <Map<String, dynamic>>[
    {
      'role': 'cyn',
      'text':
          'Chào Khải! Chúc mừng bạn đã hoàn thành Phase 1 của Foundation. Cơ thể bạn hôm nay cảm thấy thế nào?',
      'time': '09:41',
    },
    {
      'role': 'user',
      'text':
          'Cơ mình hơi mỏi phần đùi sau, và mình đang muốn tìm thực đơn bữa tối khoảng 500 kcal.',
      'time': '09:42',
      'read': true,
    },
    {
      'role': 'cyn',
      'text':
          'Đã rõ. Dựa trên dữ liệu phục hồi của bạn, CYN đã điều chỉnh bài tập ngày mai thành Thân trên (Upper Body). Về bữa tối, CYN đề xuất: 150g ức gà áp chảo, 1 bát salad rau bina trộn dầu oliu, và 100g khoai lang luộc (Tổng: 485 kcal). Bạn muốn CYN tự động thêm vào danh sách đi chợ không?',
      'time': '09:43',
    },
    {
      'role': 'user_voice',
      'duration': '0:12',
      'time': '09:44',
      'read': true,
    },
  ];

  CynChatMode _mode = CynChatMode.messaging;
  bool _isMuted = false;
  bool _isRecording = false;

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool get _isVoiceMode => _mode == CynChatMode.voiceConversation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _toggleMode() {
    setState(() {
      _mode = _isVoiceMode ? CynChatMode.messaging : CynChatMode.voiceConversation;
      if (_isVoiceMode) {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  void _endVoiceMode() {
    setState(() => _mode = CynChatMode.messaging);
  }

  void _onSendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isDark = _isVoiceMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F14) : AppColors.background,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: !_isVoiceMode,
      body: Column(
        children: [
          _CynChatAppBar(
            topPadding: topPadding,
            isDark: isDark,
            isVoiceMode: _isVoiceMode,
            onBack: () => context.popOrGoHome(),
            onToggleMode: _toggleMode,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _isVoiceMode
                  ? _VoiceConversationBody(
                      key: const ValueKey('voice'),
                      pulseAnimation: _pulseAnimation,
                      isMuted: _isMuted,
                      onToggleMute: () => setState(() => _isMuted = !_isMuted),
                      onEndCall: _endVoiceMode,
                    )
                  : _MessagingBody(
                      key: const ValueKey('messaging'),
                      scrollController: _scrollController,
                      messages: _dummyMessages,
                    ),
            ),
          ),
          if (!_isVoiceMode)
            _FrostedInputBar(
              controller: _textController,
              isRecording: _isRecording,
              onSend: _onSendText,
              onRecordStart: () => setState(() => _isRecording = true),
              onRecordEnd: () => setState(() => _isRecording = false),
            ),
        ],
      ),
    );
  }
}

class _CynChatAppBar extends StatelessWidget {
  const _CynChatAppBar({
    required this.topPadding,
    required this.isDark,
    required this.isVoiceMode,
    required this.onBack,
    required this.onToggleMode,
  });

  final double topPadding;
  final bool isDark;
  final bool isVoiceMode;
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
                            'Online',
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
            tooltip: isVoiceMode ? 'Chế độ tin nhắn' : 'Chế độ hội thoại liên tục',
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

class _MessagingBody extends StatelessWidget {
  const _MessagingBody({
    super.key,
    required this.scrollController,
    required this.messages,
  });

  final ScrollController scrollController;
  final List<Map<String, dynamic>> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final role = msg['role'] as String;
        if (role == 'cyn') {
          return _CynBubble(
            text: msg['text'] as String,
            time: msg['time'] as String?,
          );
        }
        if (role == 'user_voice') {
          return _UserVoiceBubble(
            duration: msg['duration'] as String? ?? '0:00',
            time: msg['time'] as String?,
            read: msg['read'] == true,
          );
        }
        return _UserBubble(
          text: msg['text'] as String,
          time: msg['time'] as String?,
          read: msg['read'] == true,
        );
      },
    );
  }
}

class _CynBubble extends StatelessWidget {
  const _CynBubble({required this.text, this.time});

  final String text;
  final String? time;

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
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

class _UserVoiceBubble extends StatelessWidget {
  const _UserVoiceBubble({
    required this.duration,
    this.time,
    this.read = false,
  });

  final String duration;
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
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: List.generate(18, (i) {
                      final h = 6.0 + (i % 5) * 3.5;
                      return Container(
                        width: 3,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (time != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic_rounded, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
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
    required this.onSend,
    required this.onRecordStart,
    required this.onRecordEnd,
  });

  final TextEditingController controller;
  final bool isRecording;
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
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
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
                onPressed: onSend,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded, size: 20),
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
