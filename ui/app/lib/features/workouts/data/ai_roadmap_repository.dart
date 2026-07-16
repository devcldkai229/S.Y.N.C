import 'package:sync_app/features/workouts/models/roadmap_overview_models.dart';

abstract class AiRoadmapRepository {
  Future<RoadmapOverview?> loadOverview();
}
