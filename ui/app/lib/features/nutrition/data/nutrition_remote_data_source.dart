import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/nutrition/models/nutrition_models.dart';

class NutritionRemoteDataSource {
  NutritionRemoteDataSource(this._dio);

  final Dio _dio;

  Future<DailyNutritionSummary> fetchDailySummary(DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.nutritionDailySummary,
      queryParameters: {'date': dateStr},
    );
    return _parseEnvelope(response.data, DailyNutritionSummary.fromJson);
  }

  Future<List<MealLog>> fetchMealLogs(DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.nutritionMealLogs,
      queryParameters: {'date': dateStr},
    );
    final list = _parseEnvelopeList(response.data, MealLog.fromJson);
    return list;
  }

  Future<DailyNutritionSummary> addWater(int milliliters, DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.nutritionDailySummaryWater,
      data: {'milliliters': milliliters, 'date': dateStr},
    );
    return _parseEnvelope(response.data, DailyNutritionSummary.fromJson);
  }

  Future<List<FoodItem>> searchFoods({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.nutritionFoods,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'query': query,
        'pageNumber': page,
        'pageSize': pageSize,
      },
    );
    return _parsePagedList(response.data, FoodItem.fromJson);
  }

  Future<FoodItem> getFoodById(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>(ApiPaths.nutritionFoodById(id));
    return _parseEnvelope(response.data, FoodItem.fromJson);
  }

  Future<FoodItem?> getFoodByBarcode(String barcode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.nutritionFoodByBarcode(barcode),
      );
      return _parseEnvelope(response.data, FoodItem.fromJson);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<FoodItem> createUserFood(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.nutritionFoods,
      data: body,
    );
    return _parseEnvelope(response.data, FoodItem.fromJson);
  }

  Future<MealLog> createMealLog(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.nutritionMealLogs,
      data: body,
    );
    return _parseEnvelope(response.data, MealLog.fromJson);
  }

  Future<void> deleteMealLog(String id) async {
    await _dio.delete<void>(ApiPaths.nutritionMealLogById(id));
  }

  T _parseEnvelope<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json == null || json['success'] != true) {
      throw Exception(json?['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response data');
    }
    return fromJson(data);
  }

  List<T> _parseEnvelopeList<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json == null || json['success'] != true) {
      throw Exception(json?['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  List<T> _parsePagedList<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json == null || json['success'] != true) {
      throw Exception(json?['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}
