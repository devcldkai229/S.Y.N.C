import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/context_navigation.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/cyn/models/cyn_chat_models.dart';
import 'package:sync_app/features/cyn/services/cyn_ai_chat_service.dart';

/// SYNC accent green for user chat bubbles (#DEFF9A).
const _cynAccentGreen = Color(0xFFDEFF9A);

enum CynChatMode { messaging, voiceConversation }

class CynChatScreen extends StatefulWidget {
  const CynChatScreen({super.key});

  @override
  State<CynChatScreen> createState() => _CynChatScreenState();
}

class _CynChatScreenState extends State<CynChatScreen> with TickerProviderStateMixin {
  final _ai = getIt<CynAiChatService>();
  final _sessionId = 'cyn-${DateTime.now().toUtc().millisecondsSinceEpoch}';
  final _messages = <CynChatMessage>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  CynChatMode _mode = CynChatMode.messaging;
  bool _isMuted = false;
  bool _isRecording = false;
  bool _isStreaming = false;
  CancelToken? _streamCancel;
  int _msgSeq = 0;

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

    _messages.add(
      CynChatMessage(
        id: _newMessageId(),
        role: CynMessageRole.cyn,
        text:
            'Chào bạn! Mình là CYN — coach AI của SYNC. Hỏi mình về lịch tập, dinh dưỡng hoặc gợi ý bữa ăn nhé.',
        time: _formatTime(),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  String _newMessageId() {
    _msgSeq += 1;
    return 'msg-$_msgSeq';
  }

  String _formatTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _streamCancel?.cancel('dispose');
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

  Future<void> _onSendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isStreaming) return;

    _textController.clear();
    FocusScope.of(context).unfocus();

    final cynMessageId = _newMessageId();
    setState(() {
      _messages.add(
        CynChatMessage(
          id: _newMessageId(),
          role: CynMessageRole.user,
          text: text,
          time: _formatTime(),
          read: true,
        ),
      );
      _messages.add(
        CynChatMessage(
          id: cynMessageId,
          role: CynMessageRole.cyn,
          text: '',
          time: _formatTime(),
          isStreaming: true,
        ),
      );
      _isStreaming = true;
    });
    _scrollToBottom();

    final cynIndex = _messages.indexWhere((m) => m.id == cynMessageId);
    final buffer = StringBuffer();
    _streamCancel = CancelToken();
    var hadError = false;

    void applyReplyText(String text) {
      if (text.trim().isEmpty) return;
      buffer
        ..clear()
        ..write(text);
      setState(() {
        _messages[cynIndex] = _messages[cynIndex].copyWith(text: buffer.toString());
      });
      _scrollToBottom(jump: true);
    }

    try {
      await for (final ev in _ai.streamChat(
        message: text,
        sessionId: _sessionId,
        cancelToken: _streamCancel,
      )) {
        if (!mounted || cynIndex < 0) return;

        switch (ev.type) {
          case 'token':
            buffer.write(ev.data);
            setState(() {
              _messages[cynIndex] = _messages[cynIndex].copyWith(text: buffer.toString());
            });
            _scrollToBottom(jump: true);
            break;
          case 'final':
          case 'message':
            final reply = ev.finalText;
            if (reply != null) {
              applyReplyText(reply);
            } else if (ev.data.trim().isNotEmpty) {
              buffer.write(ev.data);
              setState(() {
                _messages[cynIndex] = _messages[cynIndex].copyWith(text: buffer.toString());
              });
              _scrollToBottom(jump: true);
            }
            break;
          case 'display_payload':
            final display = ev.displayText;
            if (display != null) applyReplyText(display);
            break;
          case 'handoff':
            final payload = ev.jsonData;
            final target = payload?['to']?.toString() ?? '';
            if (target.isNotEmpty) {
              setState(() {
                _messages[cynIndex] = _messages[cynIndex].copyWith(
                  handoffLabel: 'Chuyển sang ${_agentLabel(target)}',
                );
              });
            }
            break;
          case 'pending_action':
            setState(() {
              _messages[cynIndex] = _messages[cynIndex].copyWith(pendingAction: ev.jsonData);
            });
            break;
          case 'confirm':
            setState(() {
              _messages[cynIndex] = _messages[cynIndex].copyWith(
                handoffLabel: 'Cần xác nhận trước khi đặt đơn',
              );
            });
            break;
          case 'error':
            hadError = true;
            setState(() {
              _messages[cynIndex] = _messages[cynIndex].copyWith(
                text: buffer.isEmpty ? ev.data : buffer.toString(),
                isStreaming: false,
                error: buffer.isEmpty,
              );
            });
            break;
          case 'done':
            break;
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('CYN SSE stream error [${e.runtimeType}]: $e\n$st');
      }
      final bubbleText = cynIndex >= 0 && cynIndex < _messages.length
          ? _messages[cynIndex].text.trim()
          : '';
      final hasText = buffer.toString().trim().isNotEmpty || bubbleText.isNotEmpty;
      if (!hasText) {
        hadError = true;
      }
      if (mounted && cynIndex >= 0) {
        setState(() {
          _messages[cynIndex] = _messages[cynIndex].copyWith(
            text: hasText
                ? (buffer.toString().trim().isNotEmpty ? buffer.toString() : bubbleText)
                : 'Không nhận được phản hồi từ CYN. Thử lại nhé.',
            isStreaming: false,
            error: !hasText,
          );
        });
      }
    } finally {
      _streamCancel = null;
      if (mounted && cynIndex >= 0) {
        final buffered = buffer.toString().trim();
        final bubbleText = _messages[cynIndex].text.trim();
        final resolved = buffered.isNotEmpty ? buffered : bubbleText;
        final hasSideEffects = _messages[cynIndex].pendingAction != null ||
            (_messages[cynIndex].handoffLabel?.isNotEmpty ?? false);
        setState(() {
          _messages[cynIndex] = _messages[cynIndex].copyWith(
            text: resolved.isEmpty && !hadError && !hasSideEffects
                ? 'CYN đã xử lý yêu cầu của bạn.'
                : (resolved.isEmpty ? _messages[cynIndex].text : resolved),
            isStreaming: false,
            error: resolved.isEmpty && hadError,
          );
          _isStreaming = false;
        });
        _scrollToBottom();
      }
    }
  }

  String _agentLabel(String agent) {
    return switch (agent.toLowerCase()) {
      'nutrition' => 'Dinh dưỡng',
      'workout' => 'Tập luyện',
      'commerce' => 'Đặt món',
      'insight' => 'Phân tích',
      'coach' => 'Coach',
      _ => agent,
    };
  }

  Future<void> _confirmPending(CynChatMessage message, {required bool confirmed}) async {
    final actionId = message.pendingAction?['action_id']?.toString();
    if (actionId == null || actionId.isEmpty) return;

    try {
      await _ai.confirmAction(
        sessionId: _sessionId,
        actionId: actionId,
        confirmed: confirmed,
      );
      if (!mounted) return;

      final idx = _messages.indexWhere((m) => m.id == message.id);
      setState(() {
        if (idx >= 0) {
          _messages[idx] = _messages[idx].copyWith(clearPendingAction: true);
        }
        _messages.add(
          CynChatMessage(
            id: _newMessageId(),
            role: CynMessageRole.system,
            text: confirmed ? 'Đã xác nhận đặt đơn.' : 'Đã hủy đặt đơn.',
            time: _formatTime(),
          ),
        );
      });
      _scrollToBottom();
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
            isStreaming: _isStreaming,
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
                      messages: _messages,
                      onConfirmPending: _confirmPending,
                    ),
            ),
          ),
          if (!_isVoiceMode)
            _FrostedInputBar(
              controller: _textController,
              isRecording: _isRecording,
              isBusy: _isStreaming,
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
    required this.onConfirmPending,
  });

  final ScrollController scrollController;
  final List<CynChatMessage> messages;
  final void Function(CynChatMessage message, {required bool confirmed}) onConfirmPending;

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
              text: msg.text,
              time: msg.time,
              isStreaming: msg.isStreaming,
              error: msg.error,
              handoffLabel: msg.handoffLabel,
              pendingAction: msg.pendingAction,
              onConfirm: msg.pendingAction != null
                  ? (confirmed) => onConfirmPending(msg, confirmed: confirmed)
                  : null,
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
    required this.text,
    this.time,
    this.isStreaming = false,
    this.error = false,
    this.handoffLabel,
    this.pendingAction,
    this.onConfirm,
  });

  final String text;
  final String? time;
  final bool isStreaming;
  final bool error;
  final String? handoffLabel;
  final Map<String, dynamic>? pendingAction;
  final void Function(bool confirmed)? onConfirm;

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
                Container(
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
                      : _StreamingText(
                          text: text,
                          isStreaming: isStreaming,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: error ? Colors.red.shade800 : AppColors.textPrimary,
                          ),
                        ),
                ),
                if (pendingAction != null && onConfirm != null) ...[
                  const SizedBox(height: 8),
                  _PendingActionCard(
                    action: pendingAction!,
                    onConfirm: onConfirm!,
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

class _PendingActionCard extends StatelessWidget {
  const _PendingActionCard({
    required this.action,
    required this.onConfirm,
  });

  final Map<String, dynamic> action;
  final void Function(bool confirmed) onConfirm;

  @override
  Widget build(BuildContext context) {
    final summary = action['summary']?.toString();
    final amount = action['amount'];
    final amountLabel = amount is num ? '${amount.toStringAsFixed(0)}đ' : null;

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
          const Text(
            'Xác nhận đặt đơn',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          if (summary != null && summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(summary, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
                  onPressed: () => onConfirm(false),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => onConfirm(true),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  child: const Text('Xác nhận'),
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
