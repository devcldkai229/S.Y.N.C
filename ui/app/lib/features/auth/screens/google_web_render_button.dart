// Web implementation for the circular Google Sign-In button.
// Selected by conditional import in login_screen.dart when not compiling for IO.

import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi;

/// Official GIS icon-only button sized for the 52px social circle.
Widget renderGoogleIconButton() {
  return gsi.renderButton(
    configuration: gsi.GSIButtonConfiguration(
      type: gsi.GSIButtonType.icon,
      // icon type renders as a round control; package only exposes rectangular/pill.
      shape: gsi.GSIButtonShape.pill,
      size: gsi.GSIButtonSize.large,
      theme: gsi.GSIButtonTheme.outline,
    ),
  );
}
