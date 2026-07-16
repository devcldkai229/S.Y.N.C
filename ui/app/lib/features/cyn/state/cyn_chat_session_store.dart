import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sync_app/core/utils/app_location_resolver.dart';
import 'package:sync_app/features/cyn/models/cyn_chat_models.dart';
import 'package:sync_app/features/cyn/services/cyn_ai_chat_service.dart';

enum CynChatMode { messaging, voiceConversation }

/// In-memory Cyn chat session for the app process lifetime.
/// Survives leaving `/cyn`; cleared on [clear] (logout) or app kill (RAM only).
class CynChatSessionStore extends ChangeNotifier {
  CynChatSessionStore(this._ai);

  final CynAiChatService _ai;

  final List<CynChatMessage> _messages = <CynChatMessage>[];
  String _sessionId = _newSessionId();
  CynChatMode _mode = CynChatMode.messaging;
  bool _isStreaming = false;
  bool _isConfirming = false;
  bool _seeded = false;
  CancelToken? _streamCancel;
  int _msgSeq = 0;
  String? _lastAutoSentInitial;
  double? _lastLat;
  double? _lastLng;
  String? _snackbarHint;
  bool _locationFollowUpQueued = false;
  String? _pendingLocationReason;

  List<CynChatMessage> get messages => List<CynChatMessage>.unmodifiable(_messages);
  String get sessionId => _sessionId;
  CynChatMode get mode => _mode;
  bool get isStreaming => _isStreaming;
  bool get isConfirming => _isConfirming;
  bool get isVoiceMode => _mode == CynChatMode.voiceConversation;
  String? get snackbarHint => _snackbarHint;

  void clearSnackbarHint() {
    if (_snackbarHint == null) return;
    _snackbarHint = null;
  }

  static String _newSessionId() =>
      'cyn-${DateTime.now().toUtc().millisecondsSinceEpoch}';

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

  int _indexById(String id) => _messages.indexWhere((m) => m.id == id);

  void _patchById(
    String id, {
    String? text,
    bool? isStreaming,
    bool? error,
    String? handoffLabel,
    Map<String, dynamic>? pendingAction,
    List<Map<String, dynamic>>? displayPayloads,
    bool appendDisplayPayload = false,
    Map<String, dynamic>? displayPayloadToAppend,
    bool clearPendingAction = false,
  }) {
    final idx = _indexById(id);
    if (idx < 0) return;
    var payloads = displayPayloads ?? _messages[idx].displayPayloads;
    if (appendDisplayPayload && displayPayloadToAppend != null) {
      payloads = [..._messages[idx].displayPayloads, displayPayloadToAppend];
    }
    _messages[idx] = _messages[idx].copyWith(
      text: text,
      isStreaming: isStreaming,
      error: error,
      handoffLabel: handoffLabel,
      pendingAction: pendingAction,
      displayPayloads: payloads,
      clearPendingAction: clearPendingAction,
    );
  }

  void ensureSeeded(String greeting) {
    if (_seeded || _messages.isNotEmpty) {
      _seeded = true;
      return;
    }
    _messages.add(
      CynChatMessage(
        id: _newMessageId(),
        role: CynMessageRole.cyn,
        text: greeting,
        time: _formatTime(),
      ),
    );
    _seeded = true;
    notifyListeners();
  }

  void setMode(CynChatMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void toggleMode() {
    setMode(
      _mode == CynChatMode.voiceConversation
          ? CynChatMode.messaging
          : CynChatMode.voiceConversation,
    );
  }

  void endVoiceMode() => setMode(CynChatMode.messaging);

  /// Reset for logout / new user. Generates a fresh [sessionId].
  void clear() {
    _streamCancel?.cancel('clear');
    _streamCancel = null;
    _messages.clear();
    _mode = CynChatMode.messaging;
    _isStreaming = false;
    _seeded = false;
    _msgSeq = 0;
    _lastAutoSentInitial = null;
    _sessionId = _newSessionId();
    notifyListeners();
  }

  Future<void> sendInitialIfNeeded(String? initialMessage) async {
    final text = initialMessage?.trim() ?? '';
    if (text.isEmpty || _isStreaming) return;
    if (_lastAutoSentInitial == text) return;
    final alreadyAsked = _messages.any(
      (m) => m.role == CynMessageRole.user && m.text.trim() == text,
    );
    if (alreadyAsked) {
      _lastAutoSentInitial = text;
      return;
    }
    _lastAutoSentInitial = text;
    await send(text);
  }

  Future<void> send(
    String rawText, {
    double? latitude,
    double? longitude,
    String locale = 'vi',
    String? timezone,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty || _isStreaming) return;

    if (latitude != null && longitude != null) {
      _lastLat = latitude;
      _lastLng = longitude;
    }

    final cynMessageId = _newMessageId();
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
    notifyListeners();

    final buffer = StringBuffer();
    _streamCancel = CancelToken();
    var hadError = false;
    _locationFollowUpQueued = false;

    /// Display source = token buffer. Final event replaces with cleaned full text
    /// (markdown stripped server-side) even if slightly shorter after strip.
    void preferFinalText(String reply) {
      final trimmed = reply.trim();
      if (trimmed.isEmpty) return;
      buffer
        ..clear()
        ..write(trimmed);
      _patchById(cynMessageId, text: buffer.toString());
      notifyListeners();
    }

    void appendToken(String piece) {
      buffer.write(piece);
      _patchById(cynMessageId, text: buffer.toString());
      notifyListeners();
    }

    Future<void> handleDisplayPayload(Map<String, dynamic>? payload) async {
      if (payload == null) return;
      final type = payload['type']?.toString();
      if (type == 'request_location_permission') {
        // Client-side dedupe: only one location CTA per message.
        final idx = _indexById(cynMessageId);
        if (idx >= 0) {
          final already = _messages[idx].displayPayloads.any(
            (p) => p['type']?.toString() == 'request_location_permission',
          );
          if (already) return;
        }
        _locationFollowUpQueued = true;
        final reason = payload['reason']?.toString().trim();
        _pendingLocationReason =
            (reason != null && reason.isNotEmpty) ? reason : null;
        _patchById(
          cynMessageId,
          appendDisplayPayload: true,
          displayPayloadToAppend: payload,
        );
        notifyListeners();
        return;
      }
      if (type == 'workout_plan_preview') {
        // Only attach preview onto a real pending_action (must have action_id).
        // Never invent a confirm card from preview alone — that caused frozen "Xác nhận đặt đơn".
        final idx = _indexById(cynMessageId);
        if (idx >= 0) {
          final existing = _messages[idx].pendingAction;
          final actionId = existing?['action_id']?.toString();
          if (existing != null && actionId != null && actionId.isNotEmpty) {
            _patchById(cynMessageId, pendingAction: {
              ...existing,
              'display_preview': payload,
            });
            notifyListeners();
          } else {
            _patchById(
              cynMessageId,
              appendDisplayPayload: true,
              displayPayloadToAppend: payload,
            );
            notifyListeners();
          }
        }
        return;
      }
      if (type == 'partner_list' ||
          type == 'dish_list' ||
          type == 'review_list' ||
          type == 'menu_list' ||
          type == 'payment_qr' ||
          type == 'payment_method_select' ||
          type == 'partner_detail' ||
          type == 'food_detail' ||
          type == 'exercise_media' ||
          type == 'cart' ||
          type == 'delivery_info_form' ||
          type == 'checkout_form' ||
          type == 'order_success' ||
          type == 'chart' ||
          type == 'insight_dashboard' ||
          type == 'premium_upsell' ||
          type == 'weekly_report') {
        _patchById(
          cynMessageId,
          appendDisplayPayload: true,
          displayPayloadToAppend: payload,
        );
        notifyListeners();
      }
    }

    try {
      await for (final ev in _ai.streamChat(
        message: text,
        sessionId: _sessionId,
        locale: locale,
        latitude: latitude ?? _lastLat,
        longitude: longitude ?? _lastLng,
        timezone: timezone ?? (locale.startsWith('vi') ? 'Asia/Ho_Chi_Minh' : null),
        cancelToken: _streamCancel,
      )) {
        if (_indexById(cynMessageId) < 0) return;

        switch (ev.type) {
          case 'token':
            appendToken(ev.data);
            break;
          case 'final':
            final reply = ev.finalText;
            if (reply != null) preferFinalText(reply);
            break;
          case 'display_payload':
            await handleDisplayPayload(ev.jsonData);
            break;
          case 'handoff':
            final payload = ev.jsonData;
            final target = payload?['to']?.toString() ?? '';
            if (target.isNotEmpty) {
              _patchById(
                cynMessageId,
                handoffLabel: 'Chuyển sang ${_agentLabel(target)}',
              );
              notifyListeners();
            }
            break;
          case 'pending_action':
            _patchById(cynMessageId, pendingAction: ev.jsonData);
            notifyListeners();
            break;
          case 'confirm':
            final idx = _indexById(cynMessageId);
            final pendingType = idx >= 0
                ? (_messages[idx].pendingAction?['type']?.toString() ?? '')
                : '';
            final label = switch (pendingType) {
              'plan_or_edit_workout' ||
              'generate_week_plan' ||
              'enable_ai_reschedule' =>
                'Cần xác nhận trước khi lưu lịch tập',
              'upgrade_premium' => 'Cần xác nhận nâng Premium',
              'create_order' ||
              'pay_with_wallet' ||
              'create_payment_link' =>
                'Cần xác nhận trước khi đặt đơn',
              _ => 'Cần xác nhận trước khi tiếp tục',
            };
            _patchById(cynMessageId, handoffLabel: label);
            notifyListeners();
            break;
          case 'error':
            hadError = true;
            final buffered = buffer.toString();
            _patchById(
              cynMessageId,
              text: buffered.isEmpty ? ev.data : buffered,
              isStreaming: false,
              error: buffered.isEmpty,
            );
            notifyListeners();
            break;
          case 'done':
            // Finalize streaming flag in finally; never clear text here.
            break;
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('CYN SSE stream error [${e.runtimeType}]: $e\n$st');
      }
      final idx = _indexById(cynMessageId);
      final bubbleText = idx >= 0 ? _messages[idx].text.trim() : '';
      final hasText = buffer.toString().trim().isNotEmpty || bubbleText.isNotEmpty;
      if (!hasText) hadError = true;
      if (idx >= 0) {
        _patchById(
          cynMessageId,
          text: hasText
              ? (buffer.toString().trim().isNotEmpty ? buffer.toString() : bubbleText)
              : 'Không nhận được phản hồi từ CYN. Thử lại nhé.',
          isStreaming: false,
          error: !hasText,
        );
        notifyListeners();
      }
    } finally {
      _streamCancel = null;
      final idx = _indexById(cynMessageId);
      if (idx >= 0) {
        final buffered = buffer.toString().trim();
        final bubbleText = _messages[idx].text.trim();
        // Prefer longer of buffer vs bubble (token stream wins over short final).
        final resolved = buffered.length >= bubbleText.length ? buffered : bubbleText;
        final hasSideEffects = _messages[idx].pendingAction != null ||
            (_messages[idx].handoffLabel?.isNotEmpty ?? false);
        _patchById(
          cynMessageId,
          text: resolved.isEmpty && !hadError && !hasSideEffects
              ? 'CYN đã xử lý yêu cầu của bạn.'
              : (resolved.isEmpty ? _messages[idx].text : resolved),
          isStreaming: false,
          error: resolved.isEmpty && hadError,
        );
      }
      _isStreaming = false;
      notifyListeners();
    }

    if (_locationFollowUpQueued && !_isStreaming) {
      _locationFollowUpQueued = false;
      await _fulfillLocationPermission(locale: locale);
    }
  }

  Future<void> _fulfillLocationPermission({required String locale}) async {
    final reason = _pendingLocationReason;
    _pendingLocationReason = null;
    if (reason != null && reason.isNotEmpty) {
      _snackbarHint = reason;
      notifyListeners();
    }

    final result = await AppLocationResolver.resolve(requestPermission: true);
    if (result.access == LocationAccess.granted &&
        result.lat != null &&
        result.lng != null) {
      final followUp = locale.startsWith('vi')
          ? 'Mình đã chia sẻ vị trí. Tiếp tục tìm quán gần mình giúp nhé.'
          : "I've shared my location. Please continue finding places near me.";
      await send(
        followUp,
        latitude: result.lat,
        longitude: result.lng,
        locale: locale,
      );
      return;
    }

    final denied = result.access == LocationAccess.permissionDenied ||
        result.access == LocationAccess.permissionDeniedForever;
    _snackbarHint = locale.startsWith('vi')
        ? (denied
            ? 'Bạn chưa cho phép vị trí. Bật quyền trong Cài đặt để tìm quán gần đây.'
            : 'Không lấy được vị trí lúc này. Thử lại sau nhé.')
        : (denied
            ? 'Location permission was denied. Enable it in Settings to search nearby.'
            : 'Could not get your location right now. Try again later.');
    notifyListeners();
  }

  Future<void> confirmPending(CynChatMessage message, {required bool confirmed}) async {
    final actionId = message.pendingAction?['action_id']?.toString();
    if (actionId == null || actionId.isEmpty) {
      _snackbarHint = 'Không có hành động chờ xác nhận (thiếu action_id).';
      notifyListeners();
      return;
    }
    if (_isConfirming) return;

    final actionType = message.pendingAction?['type']?.toString() ?? '';
    _isConfirming = true;
    notifyListeners();

    try {
      final result = await _ai.confirmAction(
        sessionId: _sessionId,
        actionId: actionId,
        confirmed: confirmed,
      );

      final status = result['status']?.toString();
      if (status == 'error') {
        final errMsg = result['message']?.toString() ??
            result['error']?.toString() ??
            'Không thực hiện được. Thử lại.';
        _snackbarHint = errMsg;
        // Keep pending_action so user can retry.
        return;
      }

      _patchById(message.id, clearPendingAction: true);

      final displays = result['display_payload'];
      final followUpPayloads = <Map<String, dynamic>>[];
      if (displays is List) {
        for (final raw in displays) {
          if (raw is Map) {
            final map = Map<String, dynamic>.from(raw);
            final t = map['type']?.toString() ?? '';
            if (t == 'payment_qr' || t == 'order_success') {
              followUpPayloads.add(map);
            }
          }
        }
      }

      if (confirmed && followUpPayloads.isNotEmpty) {
        final hasQr = followUpPayloads.any((p) => p['type'] == 'payment_qr');
        _messages.add(
          CynChatMessage(
            id: _newMessageId(),
            role: CynMessageRole.cyn,
            text: result['message']?.toString() ??
                (hasQr
                    ? 'Đã tạo VietQR. Quét mã hoặc mở link để thanh toán.'
                    : 'Đặt đơn thành công.'),
            time: _formatTime(),
            displayPayloads: followUpPayloads,
          ),
        );
      } else {
        final serverMsg = result['message']?.toString().trim();
        final text = confirmed
            ? (serverMsg != null && serverMsg.isNotEmpty
                ? serverMsg
                : _confirmSuccessLabel(actionType))
            : _confirmCancelLabel(actionType);
        _messages.add(
          CynChatMessage(
            id: _newMessageId(),
            role: CynMessageRole.system,
            text: text,
            time: _formatTime(),
          ),
        );
      }
    } catch (e) {
      _snackbarHint = 'Không xác nhận được: $e';
      rethrow;
    } finally {
      _isConfirming = false;
      notifyListeners();
    }
  }

  /// Manual location grant from in-chat CTA (when OS dialog didn't run yet).
  Future<void> requestLocationFromUi({String locale = 'vi'}) async {
    if (_isStreaming) return;
    await _fulfillLocationPermission(locale: locale);
  }

  static String _confirmSuccessLabel(String type) {
    return switch (type) {
      'upgrade_premium' =>
        'Đã xác nhận nâng Premium — mở VietQR để thanh toán.',
      'enable_ai_reschedule' =>
        'Đã cho phép AI chỉnh lịch và lưu lịch tập ✓',
      'plan_or_edit_workout' || 'generate_week_plan' =>
        'Đã lưu lịch tập ✓',
      'create_roadmap' || 'delete_roadmap' || 'reschedule_session' =>
        'Đã xác nhận thay đổi lộ trình.',
      'create_order' => 'Đã xác nhận đặt đơn ✓',
      'pay_with_wallet' || 'create_payment_link' => 'Đã xác nhận thanh toán.',
      'log_meal' => 'Đã xác nhận nhật ký bữa ăn.',
      _ => 'Đã xác nhận.',
    };
  }

  static String _confirmCancelLabel(String type) {
    return switch (type) {
      'upgrade_premium' ||
      'enable_ai_reschedule' ||
      'plan_or_edit_workout' ||
      'generate_week_plan' ||
      'create_roadmap' ||
      'delete_roadmap' ||
      'reschedule_session' ||
      'log_meal' =>
        'Đã hủy xác nhận.',
      'create_order' || 'pay_with_wallet' || 'create_payment_link' =>
        'Đã hủy đặt đơn.',
      _ => 'Đã hủy.',
    };
  }

  static String _agentLabel(String agent) {
    return switch (agent.toLowerCase()) {
      'nutrition' => 'Dinh dưỡng',
      'workout' => 'Tập luyện',
      'commerce' => 'Đặt món',
      'insight' => 'Phân tích',
      'coach' => 'Coach',
      _ => agent,
    };
  }
}
