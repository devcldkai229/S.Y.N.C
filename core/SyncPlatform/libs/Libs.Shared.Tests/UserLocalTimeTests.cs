using Xunit;
using Libs.Shared.Time;

namespace Libs.Shared.Tests.Time;

public class UserLocalTimeTests
{
    [Fact]
    public void ResolveTimeZone_Default_DoesNotThrow()
    {
        var tz = UserLocalTime.ResolveTimeZone(null);
        Assert.NotNull(tz);
        Assert.Equal(TimeSpan.FromHours(7), tz.GetUtcOffset(DateTime.UtcNow));
    }

    [Fact]
    public void ResolveTimeZone_AsiaHoChiMinh_DoesNotThrow()
    {
        var tz = UserLocalTime.ResolveTimeZone("Asia/Ho_Chi_Minh");
        Assert.NotNull(tz);
        Assert.Equal(TimeSpan.FromHours(7), tz.GetUtcOffset(new DateTime(2026, 1, 15)));
    }

    [Fact]
    public void DayRange_ReturnsHalfOpenLocalDay()
    {
        var date = new DateOnly(2026, 8, 10);
        var (start, end) = UserLocalTime.DayRange(date, "Asia/Ho_Chi_Minh");
        Assert.Equal(date, DateOnly.FromDateTime(start.DateTime));
        Assert.Equal(start.AddDays(1), end);
        Assert.Equal(TimeSpan.FromHours(7), start.Offset);
    }
}
