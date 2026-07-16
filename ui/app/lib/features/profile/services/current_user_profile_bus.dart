import 'dart:async';

import 'package:sync_app/features/social/models/social_models.dart';

/// Broadcasts current-user display fields after profile avatar/name updates
/// so Social (IndexedStack) can refresh without remounting.
class CurrentUserProfileBus {
  final _controller = StreamController<SocialAuthorSnapshot>.broadcast();

  Stream<SocialAuthorSnapshot> get stream => _controller.stream;

  void publish(SocialAuthorSnapshot user) {
    if (!_controller.isClosed) {
      _controller.add(user);
    }
  }

  void dispose() {
    unawaited(_controller.close());
  }
}
