import 'package:sync_app/features/order/models/tracking_update.dart';

/// Abstraction for order live tracking (mock timer or WebSocket).
///
/// SWAP POINT (injection.dart):
/// ```dart
/// // Demo:
/// getIt.registerFactory<ITrackingService>(MockTrackingService.new);
/// // Production Lalamove / SignalR:
/// getIt.registerFactory<ITrackingService>(() => WebSocketTrackingService(getIt()));
/// ```
abstract class ITrackingService {
  Stream<TrackingUpdate> watch(TrackingSession session);

  Future<void> stop();
}
