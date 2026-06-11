import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/nutrition/data/nutrition_remote_data_source.dart';
import 'package:sync_app/features/nutrition/models/nutrition_models.dart';
import 'package:sync_app/features/nutrition/theme/nutrition_theme.dart';

class FoodDetailSheet extends StatefulWidget {
  const FoodDetailSheet({super.key, required this.food, required this.mealType});

  final FoodItem food;
  final MealTypeUi mealType;

  @override
  State<FoodDetailSheet> createState() => _FoodDetailSheetState();
}

class _FoodDetailSheetState extends State<FoodDetailSheet> {
  final _api = getIt<NutritionRemoteDataSource>();
  double _grams = 100;
  bool _saving = false;
  MealTypeUi _meal = MealTypeUi.snack;

  @override
  void initState() {
    super.initState();
    _meal = widget.mealType;
    _grams = widget.food.servingSizeGram > 0 ? widget.food.servingSizeGram : 100;
  }

  int get _calories => (_grams / 100 * widget.food.caloriesPer100g).round();
  double get _protein => _grams / 100 * widget.food.proteinPer100g;
  double get _carb => _grams / 100 * widget.food.carbPer100g;
  double get _fat => _grams / 100 * widget.food.fatPer100g;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.createMealLog({
        'mealType': _meal.apiValue,
        'items': [
          {
            'foodItemId': widget.food.id,
            'quantityGram': _grams,
          },
        ],
      });
      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm vào nhật ký'), behavior: SnackBarBehavior.floating),
        );
        context.pop();
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NutritionTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.food.nameVi, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('$_calories kcal · P ${_protein.toStringAsFixed(0)}g · C ${_carb.toStringAsFixed(0)}g · F ${_fat.toStringAsFixed(0)}g'),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _grams = (_grams - 10).clamp(10, 2000)),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('${_grams.toStringAsFixed(0)} g', style: const TextStyle(fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: () => setState(() => _grams += 10),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<MealTypeUi>(
            value: _meal,
            decoration: const InputDecoration(labelText: 'Bữa'),
            items: MealTypeUi.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.apiValue)))
                .toList(),
            onChanged: (v) => setState(() => _meal = v ?? _meal),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: NutritionTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Thêm vào nhật ký'),
            ),
          ),
        ],
      ),
    );
  }
}
