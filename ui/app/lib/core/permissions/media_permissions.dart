import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests platform media permissions before opening [ImagePicker].
abstract final class MediaPermissions {
  /// True chỉ khi chạy native (Android/iOS). Web/desktop KHÔNG chạm `Platform`
  /// vì `dart:io` ném `UnsupportedError` trên web.
  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get _isNativeMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<bool> ensurePhotos(BuildContext context) {
    if (kIsWeb) return Future.value(true);
    final permissions = <Permission>[
      Permission.photos,
      if (_isAndroid) Permission.videos,
    ];
    return _ensure(
      context,
      permissions: permissions,
      label: 'thư viện ảnh',
    );
  }

  static Future<bool> ensureVideoLibrary(BuildContext context) {
    if (kIsWeb) return Future.value(true);
    final permissions = <Permission>[
      if (_isAndroid) Permission.videos else Permission.photos,
    ];
    return _ensure(
      context,
      permissions: permissions,
      label: 'thư viện video',
    );
  }

  static Future<bool> ensureCamera(BuildContext context) {
    if (kIsWeb) return Future.value(true);
    return _ensure(
      context,
      permissions: const [Permission.camera],
      label: 'camera',
    );
  }

  static Future<bool> _ensure(
    BuildContext context, {
    required List<Permission> permissions,
    required String label,
  }) async {
    if (!_isNativeMobile) return true;

    for (final permission in permissions) {
      var status = await permission.status;
      if (_isGranted(status)) continue;

      status = await permission.request();
      if (_isGranted(status)) continue;

      if (!context.mounted) return false;
      await _showSettingsDialog(context, label);
      return false;
    }

    return true;
  }

  static bool _isGranted(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  static Future<void> _showSettingsDialog(BuildContext context, String label) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cần cấp quyền'),
        content: Text(
          'Ứng dụng cần quyền truy cập $label để đăng bài. '
          'Vui lòng bật quyền trong Cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await openAppSettings();
            },
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }
}
