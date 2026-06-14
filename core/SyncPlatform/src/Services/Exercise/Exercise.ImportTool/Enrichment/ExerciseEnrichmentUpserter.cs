using Exercise.Domain.Models;

using Exercise.Domain.Repositories;

using Exercise.ImportTool.Enrichment.Models;

using Exercise.ImportTool.Services;



namespace Exercise.ImportTool.Enrichment;



public sealed class ExerciseEnrichmentUpserter

{

    private readonly IExerciseCatalogRepository _repository;



    public ExerciseEnrichmentUpserter(IExerciseCatalogRepository repository)

    {

        _repository = repository;

    }



    public async Task ApplyAsync(

        ExerciseCatalog exercise,

        LlmEnrichmentResult llm,

        CancellationToken cancellationToken = default)

    {

        var met = MetTable.ResolveMetValue(exercise);



        if (!string.IsNullOrWhiteSpace(llm.NameVi))

            exercise.NameVi = llm.NameVi.Trim();



        if (llm.InstructionsVi.Count > 0)

            exercise.AiCoachingCues = llm.InstructionsVi;



        exercise.CommonMistakes = llm.CommonMistakes;

        exercise.Contraindications = llm.Contraindications;

        exercise.RecommendedGoals = llm.RecommendedGoals;

        exercise.MovementTags = MovementTagBuilder.Build(exercise);

        exercise.MetValue = met;

        exercise.EstimatedCaloriesPerMinute = MetTable.EstimatedCaloriesPerMinute(met);

        exercise.SafetyLevel = SafetyHeuristics.ResolveSafetyLevel(exercise);

        exercise.RequiresSpotter = SafetyHeuristics.ResolveRequiresSpotter(exercise);

        exercise.NeedsReview = true;

        exercise.AiEnrichedAt = DateTimeOffset.UtcNow;

        exercise.UpdatedAt = DateTimeOffset.UtcNow;



        StringSanitizer.SanitizeCatalog(exercise);



        await _repository.UpdateAsync(exercise.Id, exercise, cancellationToken);

    }

}


