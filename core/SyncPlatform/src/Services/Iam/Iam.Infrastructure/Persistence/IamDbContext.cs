using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace Iam.Infrastructure.Persistence;

public class IamDbContext : DbContext
{
    public IamDbContext(DbContextOptions<IamDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<BiometricProfile> BiometricProfiles => Set<BiometricProfile>();
    public DbSet<UserPreference> UserPreferences => Set<UserPreference>();
    public DbSet<AIContextProfile> AIContextProfiles => Set<AIContextProfile>();
    public DbSet<GamificationProfile> GamificationProfiles => Set<GamificationProfile>();
    public DbSet<UserAsset> UserAssets => Set<UserAsset>();
    public DbSet<UserDevice> UserDevices => Set<UserDevice>();
    public DbSet<UserVoucher> UserVouchers => Set<UserVoucher>();
    public DbSet<Achievement> Achievements => Set<Achievement>();
    public DbSet<UserAchievement> UserAchievements => Set<UserAchievement>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("iam");
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(IamDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}
