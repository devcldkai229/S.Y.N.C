using System.Text.Json;
using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class BiometricProfileConfiguration : IEntityTypeConfiguration<BiometricProfile>
{
    private static readonly JsonSerializerOptions JsonOpts = new(JsonSerializerDefaults.Web);

    public void Configure(EntityTypeBuilder<BiometricProfile> builder)
    {
        builder.ToTable("biometric_profiles");

        builder.HasKey(b => b.Id);
        builder.Property(b => b.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.HasQueryFilter(b => b.DeletedAt == null);

        builder.Property(b => b.Gender).HasConversion<string>().HasMaxLength(32);
        builder.Property(b => b.FitnessGoal).HasConversion<string>().HasMaxLength(32);
        builder.Property(b => b.ActivityLevel).HasConversion<string>().HasMaxLength(32);
        builder.Property(b => b.FitnessExperienceLevel).HasConversion<string>().HasMaxLength(32);
        builder.Property(b => b.WorkoutLocationPreference).HasConversion<string>().HasMaxLength(32);

        builder.Property(b => b.HeightCm).HasPrecision(5, 2);
        builder.Property(b => b.CurrentWeightKg).HasPrecision(5, 2);
        builder.Property(b => b.TargetWeightKg).HasPrecision(5, 2);
        builder.Property(b => b.CurrentBodyFatPercentage).HasPrecision(5, 2);
        builder.Property(b => b.GoalBodyFatPercentage).HasPrecision(5, 2);
        builder.Property(b => b.MuscleMassKg).HasPrecision(5, 2);

        var listStringComparer = BuildListStringComparer();

        builder.Property(b => b.Injuries)
               .HasColumnType("jsonb")
               .HasConversion(
                   v => JsonSerializer.Serialize(v, JsonOpts),
                   v => JsonSerializer.Deserialize<List<string>>(v, JsonOpts))
               .Metadata.SetValueComparer(listStringComparer);

        builder.Property(b => b.Medications)
               .HasColumnType("jsonb")
               .HasConversion(
                   v => JsonSerializer.Serialize(v, JsonOpts),
                   v => JsonSerializer.Deserialize<List<string>>(v, JsonOpts))
               .Metadata.SetValueComparer(listStringComparer);

        builder.Property(b => b.CreatedAt).HasDefaultValueSql("now()");
    }

    private static ValueComparer<List<string>?> BuildListStringComparer() =>
        new(
            (c1, c2) => (c1 == null && c2 == null) ||
                        (c1 != null && c2 != null && c1.SequenceEqual(c2)),
            c => c == null ? 0 : c.Aggregate(0, (a, v) => HashCode.Combine(a, v.GetHashCode())),
            c => c == null ? null : c.ToList());
}
