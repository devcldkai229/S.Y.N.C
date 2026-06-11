import 'package:flutter/foundation.dart';
import 'package:sync_app/data/repositories/challenge_repository.dart';

/// Tracks per-challenge join status (synced with Social API).
class ChallengeJoinState extends ChangeNotifier {
  ChallengeJoinState(this._repository);

  final ChallengeRepository _repository;
  final Map<String, bool> _joinedByChallengeId = {};
  final Map<String, bool> _loadingByChallengeId = {};
  final Map<String, bool> _loadedByChallengeId = {};

  bool isJoined(String challengeId) => _joinedByChallengeId[challengeId] == true;

  bool isLoading(String challengeId) => _loadingByChallengeId[challengeId] == true;

  bool hasLoaded(String challengeId) => _loadedByChallengeId[challengeId] == true;

  Future<void> refreshStatus(String challengeId) async {
    if (_loadingByChallengeId[challengeId] == true) return;

    _loadingByChallengeId[challengeId] = true;

    try {
      final status = await _repository.getParticipationStatus(challengeId);
      _joinedByChallengeId[challengeId] = status.hasJoined;
      _loadedByChallengeId[challengeId] = true;
    } catch (_) {
      _loadedByChallengeId[challengeId] = true;
      _joinedByChallengeId.putIfAbsent(challengeId, () => false);
    } finally {
      _loadingByChallengeId[challengeId] = false;
      notifyListeners();
    }
  }

  Future<void> join(String challengeId) async {
    await _repository.join(challengeId);
    _joinedByChallengeId[challengeId] = true;
    _loadedByChallengeId[challengeId] = true;
    notifyListeners();
  }

  Future<void> leave(String challengeId) async {
    await _repository.leave(challengeId);
    _joinedByChallengeId[challengeId] = false;
    _loadedByChallengeId[challengeId] = true;
    notifyListeners();
  }
}
