import 'package:sync_app/features/challenges/data/challenge_remote_data_source.dart';
import 'package:sync_app/features/challenges/models/challenge_models.dart';
import 'package:sync_app/features/challenges/models/challenge_participation_models.dart';
import 'package:sync_app/features/challenges/models/challenge_route_models.dart';

class ChallengeRepository {
  ChallengeRepository(this._remote);

  final ChallengeRemoteDataSource _remote;

  /// List endpoint only (no geo/nearby). Home shows a small slice; map loads more on open.
  Future<List<CommunityChallenge>> getChallenges({int pageSize = 40}) =>
      _remote.fetchChallenges(pageSize: pageSize);

  Future<CommunityChallenge> getById(String id) => _remote.fetchChallengeById(id);

  Future<ChallengeParticipationStatus> getParticipationStatus(String challengeId) =>
      _remote.fetchParticipationStatus(challengeId);

  Future<void> join(String challengeId) => _remote.joinChallenge(challengeId);

  Future<void> leave(String challengeId) => _remote.leaveChallenge(challengeId);

  Future<ChallengeRoute> getRoute({
    required String challengeId,
    required double userLat,
    required double userLng,
    String? travelMode,
  }) =>
      _remote.fetchRoute(
        challengeId: challengeId,
        userLat: userLat,
        userLng: userLng,
        travelMode: travelMode,
      );
}
