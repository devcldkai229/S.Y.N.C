import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/nutrition/data/nutrition_remote_data_source.dart';
import 'package:sync_app/features/nutrition/models/nutrition_models.dart';
import 'package:sync_app/features/nutrition/screens/food_detail_sheet.dart';
import 'package:sync_app/features/nutrition/theme/nutrition_theme.dart';
import 'package:sync_app/features/nutrition/widgets/food_row.dart';
import 'package:sync_app/shared/widgets/sync_shimmer_box.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key, required this.mealType});

  final MealTypeUi mealType;

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _api = getIt<NutritionRemoteDataSource>();
  final _controller = TextEditingController();
  List<FoodItem> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
    _controller.addListener(() => _search(query: _controller.text));
  }

  Future<void> _search({String? query}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.searchFoods(query: query);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(FoodItem food) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FoodDetailSheet(food: food, mealType: widget.mealType),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NutritionTheme.background,
      appBar: AppBar(
        backgroundColor: NutritionTheme.background,
        title: const Text('Tìm & thêm món'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Tìm món ăn...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: null,
                  tooltip: 'Quét barcode — sắp ra mắt',
                  icon: Icon(Icons.qr_code_scanner, color: Colors.grey.shade400),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: NutritionTheme.border),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? ListView.builder(
                    itemCount: 8,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: SyncShimmerBox(height: 56),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Không tải được. Thử lại nhé.'),
                            TextButton(onPressed: _search, child: const Text('Thử lại')),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _items.length) {
                            return ListTile(
                              title: const Text('Không thấy? Tạo món mới'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => context.push(AppRoutes.nutritionCreateFood),
                            );
                          }
                          final food = _items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: FoodRow(
                              name: food.nameVi,
                              subtitle:
                                  '${food.brand ?? 'SYNC'} · ${food.caloriesPer100g} kcal/100g',
                              onTap: () => _openDetail(food),
                              onAdd: () => _openDetail(food),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
