import 'package:sync_app/features/challenges/models/challenge_models.dart';

/// Seed IDs aligned with Social service `SocialSeedData` challenge GUIDs.
const challengeActiveId = 'c8000001-0000-0000-0000-000000000001';
const challengeUpcomingId = 'c8000002-0000-0000-0000-000000000002';
const challengeCompletedId = 'c8000003-0000-0000-0000-000000000003';

const mockUserLocationLat = 10.7769;
const mockUserLocationLng = 106.7009;

final List<MockChallenge> mockChallenges = [
  MockChallenge(
    id: challengeActiveId,
    title: 'Thử thách 100km Tháng 6',
    description:
        'Cùng nhau chạy/đạp tổng 100km trong tháng 6. Hoàn thành để nhận 500 điểm SYNC!',
    goalType: ChallengeGoalType.totalDistance,
    targetValue: 100,
    unit: 'km',
    startDate: _june1,
    endDate: _june30,
    participantCount: 5,
    pointRewards: 500,
    gifts: ['Badge 100K', 'Áo thun SYNC'],
    address: 'Công viên Tao Đàn, Quận 1, TP.HCM',
    lat: 10.762622,
    lng: 106.660172,
    status: 'InProgress',
    distanceFromUserKm: 2.3,
    filter: ChallengeFilter.running,
  ),
  MockChallenge(
    id: challengeUpcomingId,
    title: 'Thử thách Đốt mỡ 5000 Kcal',
    description:
        'Đốt cháy 5000 kcal trong 30 ngày thông qua cardio và strength training.',
    goalType: ChallengeGoalType.totalCaloriesBurned,
    targetValue: 5000,
    unit: 'calo',
    startDate: _june1,
    endDate: _june30,
    participantCount: 0,
    pointRewards: 400,
    gifts: ['Shaker SYNC'],
    address: 'Landmark 81, Bình Thạnh, TP.HCM',
    lat: 10.7951,
    lng: 106.7220,
    status: 'Active',
    distanceFromUserKm: 1.5,
    filter: ChallengeFilter.calories,
  ),
  MockChallenge(
    id: challengeCompletedId,
    title: 'Chuỗi 14 ngày Workout',
    description: 'Tập luyện liên tục 14 ngày — không bỏ lỡ một buổi nào!',
    goalType: ChallengeGoalType.totalWorkouts,
    targetValue: 14,
    unit: 'buổi',
    startDate: _june1,
    endDate: _june30,
    participantCount: 4,
    pointRewards: 300,
    gifts: ['Voucher 200k'],
    address: 'SYNC Fitness Hub, Quận 7, TP.HCM',
    lat: 10.7295,
    lng: 106.7204,
    status: 'Completed',
    distanceFromUserKm: 4.8,
    filter: ChallengeFilter.workouts,
  ),
];

final _june1 = DateTime(2026, 6, 1);
final _june30 = DateTime(2026, 6, 30);

MockChallenge? challengeById(String id) {
  for (final c in mockChallenges) {
    if (c.id == id) return c;
  }
  return null;
}

const participantAvatarUrls = [
  'https://picsum.photos/seed/ch-p1/80/80',
  'https://picsum.photos/seed/ch-p2/80/80',
  'https://picsum.photos/seed/ch-p3/80/80',
  'https://picsum.photos/seed/ch-p4/80/80',
  'https://picsum.photos/seed/ch-p5/80/80',
];
