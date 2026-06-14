import 'package:flutter/material.dart';

/// In-app toast with a close (×) control on every notification.
void showSyncSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 4),
  Color? backgroundColor,
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      duration: duration,
      showCloseIcon: true,
      closeIconColor: Colors.white70,
      content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
      action: action,
    ),
  );
}
