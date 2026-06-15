import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/context_navigation.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/challenge_repository.dart';
import 'package:sync_app/features/challenges/models/challenge_models.dart';
import 'package:sync_app/features/challenges/models/challenge_route_models.dart';
import 'package:sync_app/features/challenges/state/challenge_join_state.dart';
import 'package:sync_app/features/challenges/utils/challenge_user_location.dart';
import 'package:sync_app/features/challenges/utils/route_polyline_utils.dart';
import 'package:sync_app/features/challenges/widgets/aws_location_map.dart';
import 'package:sync_app/features/challenges/widgets/challenge_info_card.dart';
import 'package:sync_app/features/challenges/widgets/challenge_join_flow.dart';
import 'package:sync_app/features/challenges/widgets/challenge_map_marker.dart';
import 'package:sync_app/features/challenges/widgets/route_callout_marker.dart';

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({
    super.key,
    required this.challengeId,
    this.initialMode = TravelMode.motorbike,
  });

  final String challengeId;
  final TravelMode initialMode;

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final _mapKey = GlobalKey<AwsLocationMapState>();
  bool _showInfoCard = false;
  bool _loadingRoute = true;
  String? _routeError;
  TravelModeRouteInfo? _routeInfo;
  List<LatLng> _routePoints = [];
  List<LatLng> _walkingConnector = [];
  LatLng? _userPoint;
  LatLng? _calloutPoint;

  CommunityChallenge? _challenge;
  bool _loadingChallenge = true;

  ChallengeJoinState get _joinState => getIt<ChallengeJoinState>();
  ChallengeRepository get _repository => getIt<ChallengeRepository>();

  @override
  void initState() {
    super.initState();
    _joinState.refreshStatus(widget.challengeId);
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    try {
      final challenge = await _repository.getById(widget.challengeId);
      if (mounted) setState(() => _challenge = challenge);
      await _loadRoute();
    } catch (_) {
      if (mounted) setState(() => _routeError = 'Không tải được thử thách');
    } finally {
      if (mounted) setState(() => _loadingChallenge = false);
    }
  }

  Future<void> _loadRoute() async {
    final challenge = _challenge;
    if (challenge == null) return;

    setState(() {
      _loadingRoute = true;
      _routeError = null;
      _routePoints = [];
      _walkingConnector = [];
      _routeInfo = null;
      _calloutPoint = null;
    });

    try {
      final userPoint = await ChallengeUserLocation.resolve();
      final route = await _repository.getRoute(
        challengeId: challenge.id,
        userLat: userPoint.latitude,
        userLng: userPoint.longitude,
        travelMode: 'Motorbike',
      );

      final modeRoute = route.motorbike;
      if (modeRoute.polyline.length < 2) {
        throw Exception('Không nhận được đường đi từ máy chủ.');
      }

      final destination = challenge.location;
      final points = trimOffRoadPolyline(
        polyline: modeRoute.polyline,
        origin: userPoint,
        destination: destination,
      );

      final gapM = modeRoute.offRoadGapMeters > 0
          ? modeRoute.offRoadGapMeters
          : offRoadGapMeters(points, destination);
      final connector = gapM >= 30 ? [points.last, destination] : <LatLng>[];

      if (!mounted) return;
      setState(() {
        _userPoint = userPoint;
        _routeInfo = modeRoute;
        _routePoints = points;
        _walkingConnector = connector;
        _calloutPoint = polylineMidpoint(points);
        _loadingRoute = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapKey.currentState?.fitToPoints([
          userPoint,
          destination,
          if (points.isNotEmpty) points.first,
          if (points.length > 1) points.last,
        ]);
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _routeError = _routeErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRoute = false;
        _routeError = 'Không tính được đường đi. Kiểm tra AWS Location và thử lại.';
      });
    }
  }

  List<MapMarkerData> _buildMarkers(MockChallenge challenge) {
    final userPoint = _userPoint;
    if (userPoint == null) return [];

    final info = _routeInfo;
    final calloutLabel = info == null
        ? null
        : '🛵 Xe máy\n${info.distanceLabel} · ${info.durationLabel}';

    final markers = <MapMarkerData>[
      MapMarkerData(
        id: 'origin',
        point: userPoint,
        alignment: Alignment.center,
        width: 40,
        height: 40,
        annotationIsCircle: true,
        annotationColor: const Color(0xFF2563EB),
        child: const _OriginMarker(),
      ),
      MapMarkerData(
        id: 'destination',
        point: challenge.location,
        alignment: Alignment.center,
        width: 44,
        height: 44,
        annotationLabel: challenge.goalEmoji,
        child: ChallengeMapMarker(challenge: challenge, compact: true),
        onTap: () => setState(() => _showInfoCard = true),
      ),
    ];

    final callout = _calloutPoint;
    if (callout != null && calloutLabel != null) {
      markers.add(
        MapMarkerData(
          id: 'route-callout',
          point: callout,
          alignment: Alignment.bottomCenter,
          width: 180,
          height: 72,
          annotationLabel: calloutLabel,
          child: RouteCalloutMarker(routeInfo: info!),
        ),
      );
    }

    return markers;
  }

  String _routeErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }

    return switch (error.response?.statusCode) {
      400 => 'Thử thách này không hỗ trợ xem đường đi.',
      404 => 'Không tìm thấy thử thách hoặc thử thách đã kết thúc.',
      _ => 'Không tính được đường đi. Kiểm tra AWS Location và thử lại.',
    };
  }

  String _walkingConnectorLabel() {
    if (_walkingConnector.length < 2) return '';
    final gapM = offRoadGapMeters(_routePoints, _walkingConnector.last);
    if (gapM < 30) return '';
    if (gapM >= 1000) {
      return 'Còn ~${(gapM / 1000).toStringAsFixed(1)} km đi bộ đến điểm gặp';
    }
    return 'Còn ~${gapM.round()} m đi bộ đến điểm gặp';
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenge;
    if (challenge == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đường đi')),
        body: Center(
          child: _loadingChallenge
              ? const CircularProgressIndicator()
              : Text(_routeError ?? 'Không tìm thấy thử thách'),
        ),
      );
    }

    final userPoint = _userPoint ?? ChallengeUserLocation.fallback;
    final mapCenter = LatLng(
      (userPoint.latitude + challenge.lat) / 2,
      (userPoint.longitude + challenge.lng) / 2,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.popOrGoHome(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
        ),
        title: const Text(
          'Đường đi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        actions: [
          if (_routeError != null)
            IconButton(
              onPressed: _loadRoute,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Tải lại',
            ),
        ],
      ),
      body: Stack(
        children: [
          AwsLocationMap(
            key: _mapKey,
            initialCenter: mapCenter,
            initialZoom: 13,
            polylines: _routePoints,
            walkingConnector: _walkingConnector,
            showUserLocation: false,
            markers: _buildMarkers(challenge),
          ),
          if (_loadingRoute)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Đang tính đường đi...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_routeError != null && !_loadingRoute)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _routeError!,
                    style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                  ),
                ),
              ),
            ),
          if (!_loadingRoute &&
              _routeError == null &&
              _walkingConnector.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.directions_walk_rounded, size: 18, color: Colors.blue.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _walkingConnectorLabel(),
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showInfoCard)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showInfoCard = false),
                child: Container(color: Colors.black.withValues(alpha: 0.12)),
              ),
            ),
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            offset: _showInfoCard ? Offset.zero : const Offset(0, 1.2),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ListenableBuilder(
                listenable: _joinState,
                builder: (context, _) => ChallengeInfoCard(
                  challenge: challenge,
                  joinState: _joinState,
                  compact: true,
                  onViewDetail: () {
                    setState(() => _showInfoCard = false);
                    context.push(AppRoutes.challengeDetail(challenge.id));
                  },
                  onJoin: () => ChallengeJoinFlow.confirmJoin(
                    context,
                    challenge: challenge,
                    joinState: _joinState,
                  ),
                  onLeave: () => ChallengeJoinFlow.confirmLeave(
                    context,
                    challenge: challenge,
                    joinState: _joinState,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OriginMarker extends StatelessWidget {
  const _OriginMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2563EB),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
