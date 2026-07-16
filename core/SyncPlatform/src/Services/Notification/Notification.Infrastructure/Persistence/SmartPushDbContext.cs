using Microsoft.EntityFrameworkCore;
using Notification.Domain.Models;

namespace Notification.Infrastructure.Persistence;

public class SmartPushDbContext : DbContext
{
    public SmartPushDbContext(DbContextOptions<SmartPushDbContext> options) : base(options)
    {
    }

    public DbSet<SmartPushSchedule> SmartPushSchedules => Set<SmartPushSchedule>();
    public DbSet<SmartPushLog> SmartPushLogs => Set<SmartPushLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("smart_push");

        modelBuilder.Entity<SmartPushSchedule>(b =>
        {
            b.ToTable("smart_push_schedule");
            b.HasKey(x => x.UserId);
            b.Property(x => x.Timezone).HasMaxLength(64).IsRequired();
            b.Property(x => x.LastTrigger).HasMaxLength(64);
            b.HasIndex(x => x.NextFireAtUtc)
                .HasDatabaseName("ix_sps_due")
                .HasFilter("enabled = true AND next_fire_at_utc IS NOT NULL");
        });

        modelBuilder.Entity<SmartPushLog>(b =>
        {
            b.ToTable("smart_push_log");
            b.HasKey(x => x.Id);
            b.Property(x => x.Trigger).HasMaxLength(64).IsRequired();
            b.Property(x => x.DedupKey).HasMaxLength(160).IsRequired();
            b.Property(x => x.Channel).HasMaxLength(32).IsRequired();
            b.Property(x => x.Title).HasMaxLength(80);
            b.Property(x => x.Body).HasMaxLength(280);
            b.HasIndex(x => x.DedupKey).IsUnique().HasDatabaseName("ux_sps_log_dedup");
            b.HasIndex(x => new { x.UserId, x.LocalDate }).HasDatabaseName("ix_sps_log_user_date");
        });
    }
}
