// Stub for non-Web platforms.
// On Web, the real `package:google_sign_in_web/web_only.dart` is used instead.
// This file is selected by the conditional import in login_screen.dart when
// `dart.library.io` is available (i.e., Android / iOS / desktop).

import 'package:flutter/material.dart';

/// No-op stub — renderButton() is never called on non-Web platforms because
/// _GoogleWebButtonWrapper is only rendered when kIsWeb == true.
Widget renderButton() => const SizedBox.shrink();
