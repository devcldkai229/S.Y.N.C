using System.Text.Json;
using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class UserPreferenceConfiguration : IEntityTypeConfiguration<UserPreference>
{
    private static readonly JsonSerializerOptions JsonOpts = new(JsonSerializerDefaults.Web);

    public void Configure(EntityTypeBuilder<UserPreference> builder)
    {
        builder.ToTable("user_preferences");

        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.HasQueryFilter(p => p.DeletedAt == null);

        builder.Property(p => p.AgentPersona).HasConversion<string>().HasMaxLength(32);
        builder.Property(p => p.MotivationStyle).HasConversion<string>().HasMaxLength(32);

        builder.Property(p => p.MaxAutoOrderLimitDaily).HasPrecision(18, 2);
        builder.Property(p => p.MaxAutoOrderLimitPerOrder).HasPrecision(18, 2);

        var listStringComparer = BuildListStringComparer();
        var allergyComparer = BuildAllergyComparer();

        builder.Property(p => p.Allergies)
               .HasColumnType("jsonb")
               .HasConversion(
                   v => JsonSerializer.Serialize(v, JsonOpts),
                   v => JsonSerializer.Deserialize<List<AllergyItem>>(v, JsonOpts))
               .Metadata.SetValueComparer(allergyComparer);

        builder.Property(p => p.FavoriteFoods)
               .HasColumnType("jsonb")
               .HasConversion(
                   v => JsonSerializer.Serialize(v, JsonOpts),
                   v => JsonSerializer.Deserialize<List<string>>(v, JsonOpts))
               .Metadata.SetValueComparer(listStringComparer);

        builder.Property(p => p.DislikedFoods)
               .HasColumnType("jsonb")
               .HasConversion(
                   v => JsonSerializer.Serialize(v, JsonOpts),
                   v => JsonSerializer.Deserialize<List<string>>(v, JsonOpts))
               .Metadata.SetValueComparer(listStringComparer);

        builder.Property(p => p.CreatedAt).HasDefaultValueSql("now()");
    }

    private static ValueComparer<List<string>?> BuildListStringComparer() =>
        new(
            (c1, c2) => (c1 == null && c2 == null) ||
                        (c1 != null && c2 != null && c1.SequenceEqual(c2)),
            c => c == null ? 0 : c.Aggregate(0, (a, v) => HashCode.Combine(a, v.GetHashCode())),
            c => c == null ? null : c.ToList());

    private static ValueComparer<List<AllergyItem>?> BuildAllergyComparer() =>
        new(
            (c1, c2) => (c1 == null && c2 == null) ||
                        (c1 != null && c2 != null && c1.SequenceEqual(c2)),
            c => c == null ? 0 : c.Aggregate(0, (a, v) => HashCode.Combine(a, v.GetHashCode())),
            c => c == null ? null : c.ToList());
}
