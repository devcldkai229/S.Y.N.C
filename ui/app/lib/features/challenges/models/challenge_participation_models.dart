class ChallengeParticipationStatus {
  const ChallengeParticipationStatus({
    required this.hasJoined,
    this.status,
  });

  final bool hasJoined;
  final String? status;

  factory ChallengeParticipationStatus.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipationStatus(
      hasJoined: json['hasJoined'] == true,
      status: json['status']?.toString(),
    );
  }
}
