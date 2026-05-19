using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class AIContextProfileConfiguration : IEntityTypeConfiguration<AIContextProfile>
{
    public void Configure(EntityTypeBuilder<AIContextProfile> builder)
    {
        builder.ToTable("ai_context_profiles");

        builder.HasKey(a => a.Id);

        builder.HasQueryFilter(x => x.DeletedAt == null);
        builder.Property(a => a.Id).HasDefaultValueSql("gen_random_uuid()");

        // All score columns share the same precision — 0–100 range, 4 decimal places
        foreach (var col in new[]
        {
            nameof(AIContextProfile.AdherenceScore),
            nameof(AIContextProfile.BurnoutRiskScore),
            nameof(AIContextProfile.ChurnRiskScore),
            nameof(AIContextProfile.MotivationScore),
            nameof(AIContextProfile.RecoveryScore),
            nameof(AIContextProfile.StressScore),
            nameof(AIContextProfile.SleepQualityScore),
            nameof(AIContextProfile.NutritionComplianceScore),
            nameof(AIContextProfile.WorkoutComplianceScore),
            nameof(AIContextProfile.AIConfidenceScore),
        })
        {
            builder.Property(col).HasColumnType("numeric(6,4)");
        }

        builder.Property(a => a.PeakEnergyTimeWindow).HasMaxLength(64);
        builder.Property(a => a.PreferredInterventionStyle).HasMaxLength(64);
        builder.Property(a => a.CurrentMood).HasMaxLength(64);

        builder.Property(a => a.CreatedAt).HasDefaultValueSql("now()");
    }
}
