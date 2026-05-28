/// Display labels for backend enum values on profile screens.
abstract final class ProfileEnums {
  static const fitnessGoals = {
    'LoseFat': 'Giảm mỡ',
    'BuildMuscle': 'Tăng cơ',
    'Maintain': 'Duy trì',
    'Recomposition': 'Tái cấu trúc',
    'ImproveEndurance': 'Sức bền',
    'GeneralHealth': 'Sức khỏe tổng quát',
  };

  static const activityLevels = {
    'Sedentary': 'Ít vận động',
    'LightlyActive': 'Vận động nhẹ',
    'ModeratelyActive': 'Vừa phải',
    'VeryActive': 'Năng động',
    'Athlete': 'Vận động viên',
  };

  static const experienceLevels = {
    'Beginner': 'Mới bắt đầu',
    'Intermediate': 'Trung cấp',
    'Advanced': 'Nâng cao',
  };

  static const workoutLocations = {
    'Home': 'Ở nhà',
    'Gym': 'Phòng gym',
    'Outdoor': 'Ngoài trời',
    'Hybrid': 'Kết hợp',
  };

  static const agentPersonas = {
    'StrictCoach': 'HLV nghiêm khắc',
    'FriendlyBuddy': 'Bạn đồng hành',
    'CalmMentor': 'Cố vấn điềm tĩnh',
    'EnergeticTrainer': 'HLV năng lượng',
  };

  static const motivationStyles = {
    'Supportive': 'Động viên nhẹ nhàng',
    'Aggressive': 'Thúc đẩy mạnh',
    'DisciplineFocused': 'Kỷ luật',
    'Friendly': 'Thân thiện',
    'Competitive': 'Cạnh tranh',
    'Minimal': 'Ngắn gọn',
  };

  static String label(Map<String, String> map, String? key) {
    if (key == null || key.isEmpty) return '—';
    return map[key] ?? key;
  }
}
