import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/nutrition/data/nutrition_remote_data_source.dart';
import 'package:sync_app/features/nutrition/theme/nutrition_theme.dart';

class CreateFoodScreen extends StatefulWidget {
  const CreateFoodScreen({super.key});

  @override
  State<CreateFoodScreen> createState() => _CreateFoodScreenState();
}

class _CreateFoodScreenState extends State<CreateFoodScreen> {
  final _api = getIt<NutritionRemoteDataSource>();
  final _nameVi = TextEditingController();
  final _nameEn = TextEditingController();
  final _serving = TextEditingController(text: '100');
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carb = TextEditingController();
  final _fat = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.createUserFood({
        'nameVi': _nameVi.text.trim(),
        'nameEn': _nameEn.text.trim(),
        'category': 'Snack',
        'servingSizeGram': double.tryParse(_serving.text) ?? 100,
        'caloriesPer100g': int.tryParse(_calories.text) ?? 0,
        'proteinPer100g': double.tryParse(_protein.text) ?? 0,
        'carbPer100g': double.tryParse(_carb.text) ?? 0,
        'fatPer100g': double.tryParse(_fat.text) ?? 0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu món mới'), behavior: SnackBarBehavior.floating),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NutritionTheme.background,
      appBar: AppBar(
        backgroundColor: NutritionTheme.background,
        title: const Text('Tạo món tự nhập'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_nameVi, 'Tên (VI)'),
          _field(_nameEn, 'Tên (EN)'),
          _field(_serving, 'Khẩu phần (gram)'),
          _field(_calories, 'Calo / 100g'),
          _field(_protein, 'Đạm / 100g (g)'),
          _field(_carb, 'Tinh bột / 100g (g)'),
          _field(_fat, 'Béo / 100g (g)'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: NutritionTheme.primary),
            child: const Text('Lưu món'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
}
