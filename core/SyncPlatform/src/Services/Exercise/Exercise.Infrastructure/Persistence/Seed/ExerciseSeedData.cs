using Exercise.Domain.Models;
using MongoDB.Driver;

namespace Exercise.Infrastructure.Persistence.Seed;

/// <summary>
/// Thin guard seeder: exercises come from 'import-free-exercise-db', not from hardcoded fakes.
/// </summary>
public static class ExerciseSeedData
{
    public static class ExerciseMongoSeeder
    {
        public static async Task SeedAsync(IMongoDatabase database)
        {
            var catalog = database.GetCollection<ExerciseCatalog>("ExerciseCatalog");

            if (await catalog.Find(_ => true).AnyAsync())
            {
                Console.WriteLine("[ExerciseSeed] ExerciseCatalog already populated — skipping seed.");
                return;
            }

            Console.WriteLine("[ExerciseSeed] ExerciseCatalog is empty. Run 'import-free-exercise-db' to populate catalog before seeding roadmap data.");
        }
    }
}
