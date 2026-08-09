// Stub for non-Web platforms.
// On Web, [google_web_render_button.dart] is used instead via conditional import
// in login_screen.dart when `dart.library.io` is unavailable.

import 'package:flutter/material.dart';

/// No-op stub — only rendered when kIsWeb == true (never on this import).
Widget renderGoogleIconButton() => const SizedBox.shrink();
