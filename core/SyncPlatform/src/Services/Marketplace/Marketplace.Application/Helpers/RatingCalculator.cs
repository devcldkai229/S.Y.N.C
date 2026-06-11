namespace Marketplace.Application.Helpers;

public static class RatingCalculator
{
    public static (decimal Average, int Count) AddRating(decimal currentAverage, int currentCount, int newRating)
    {
        var newCount = currentCount + 1;
        var newAverage = ((currentAverage * currentCount) + newRating) / newCount;
        return (Math.Round(newAverage, 2, MidpointRounding.AwayFromZero), newCount);
    }
}
