/// Tag lists from [onboarding.txt] — injuries, allergies, favorite & disliked foods.
abstract final class OnboardingTagCatalog {
  static const noneInjury = 'Không có chấn thương đặc biệt';
  static const noneAllergy = 'Không có dị ứng đặc biệt';

  static const injuriesPopular = [
    'Đau cổ vai gáy',
    'Đau thắt lưng (Đau lưng dưới)',
    'Viêm khớp gối / Tràn dịch khớp gối',
    'Thoát vị đĩa đệm',
    'Đau khớp cổ tay / Hội chứng ống cổ tay',
    noneInjury,
  ];

  static const allergiesPopular = [
    'Đậu phộng (Lạc)',
    'Hải sản nói chung',
    'Sữa bò (Bất dung nạp Lactose)',
    'Lúa mì / Không dung nạp Gluten',
    'Tôm',
    noneAllergy,
  ];

  static const favoriteFoodsPopular = [
    'Cơm tấm sườn bì chả',
    'Phở bò / Phở gà',
    'Bún bò Huế',
    'Trà sữa trân châu',
    'Gà rán / Hamburger (Fast food)',
    'Bún chả Hà Nội',
  ];

  static const dislikedFoodsPopular = [
    'Hành lá / Hành tây sống',
    'Rau mùi (Ngò gai, ngò rí)',
    'Mắm tôm / Mắm nêm / Mắm ruốc',
    'Sầu riêng',
    'Ức gà khô (Nỗi ám ảnh của dân tập gym)',
    'Đồ ăn quá cay',
  ];

  static const injuries = [
    'Thoát vị đĩa đệm',
    'Đau thần kinh tọa',
    'Đau thắt lưng (Đau lưng dưới)',
    'Đau cổ vai gáy',
    'Viêm khớp gối / Tràn dịch khớp gối',
    'Đứt dây chằng chéo (ACL)',
    'Tổn thương sụn chêm',
    'Đau khớp cổ tay / Hội chứng ống cổ tay',
    'Trật khớp vai / Lỏng khớp vai',
    'Viêm chóp xoay vai (Rotator cuff)',
    'Lật sơ mi / Bong gân mắt cá chân',
    'Đau khuỷu tay (Tennis Elbow)',
    'Viêm cân gan chân (Đau gót chân)',
    'Thoái hóa cột sống',
    'Huyết áp cao / Bệnh tim mạch',
    'Hen suyễn / Khó thở',
    'Giãn tĩnh mạch chi dưới',
    'Tràn dịch khớp',
    'Gù lưng / Võng lưng (Sai tư thế)',
    'Đang phục hồi sau phẫu thuật (Cần AI cực kỳ cẩn trọng)',
    noneInjury,
  ];

  static const allergies = [
    'Đậu phộng (Lạc)',
    'Sữa bò (Bất dung nạp Lactose)',
    'Hải sản nói chung',
    'Tôm',
    'Cua / Ghẹ',
    'Mực / Bạch tuộc',
    'Đậu nành',
    'Lúa mì / Không dung nạp Gluten',
    'Trứng',
    'Hạt điều / Hạt mắc ca (Tree nuts)',
    'Cá biển (Cá ngừ, cá hồi, cá thu...)',
    'Bột ngọt / Mì chính (Cực kỳ phổ biến ở Việt Nam)',
    'Nhộng tằm / Côn trùng',
    'Đồ lên men (Mắm, dưa muối)',
    'Sứa biển',
    'Nấm các loại',
    'Dứa (Thơm)',
    'Phẩm màu / Chất bảo quản',
    'Đồ uống có cồn (Bia, rượu)',
    'Caffeine (Say cà phê/trà)',
    noneAllergy,
  ];

  static const favoriteFoods = [
    'Phở bò / Phở gà',
    'Bún bò Huế',
    'Cơm tấm sườn bì chả',
    'Bún chả Hà Nội',
    'Bánh mì thịt / Bánh mì chảo',
    'Bún đậu mắm tôm',
    'Bún thịt nướng',
    'Heo quay / Vịt quay Bắc Kinh',
    'Gà rán / Hamburger (Fast food)',
    'Lẩu Thái / Lẩu hải sản',
    'Ốc / Đồ nướng vỉa hè',
    'Trà sữa trân châu',
    'Đồ nướng BBQ Hàn Quốc (Kogi)',
    'Hủ tiếu Nam Vang',
    'Bánh xèo / Bánh khọt',
    'Xôi mặn / Xôi xéo',
    'Mì Quảng',
    'Gỏi cuốn / Bò bía',
    'Sushi / Sashimi',
    'Chè / Đồ ngọt tráng miệng',
  ];

  static const dislikedFoods = [
    'Hành lá / Hành tây sống',
    'Rau mùi (Ngò gai, ngò rí)',
    'Rau diếp cá (Mùi tanh)',
    'Khổ qua (Mướp đắng)',
    'Mắm tôm / Mắm nêm / Mắm ruốc',
    'Đồ lòng / Nội tạng động vật',
    'Sầu riêng',
    'Tiết canh / Đồ sống',
    'Thịt mỡ / Da động vật',
    'Cà chua sống',
    'Giá đỗ',
    'Măng tươi / Măng chua',
    'Ớt chuông',
    'Các loại rau luộc nhạt nhẽo',
    'Cá sông / Đồ ăn có mùi tanh',
    'Ức gà khô (Nỗi ám ảnh của dân tập gym)',
    'Khoai lang luộc',
    'Đồ ăn quá cay',
    'Đồ ăn nhiều dầu mỡ (Ngấy)',
    'Các loại thịt nạc dăm / Gân cứng',
  ];
}
