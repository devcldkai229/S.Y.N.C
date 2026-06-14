namespace Marketplace.SeedTool.Models;

public sealed class SeedReport
{
    public int PartnersCreated { get; set; }

    public int PartnersUpdated { get; set; }

    public int PartnersSkipped { get; set; }

    public int PartnersFailed { get; set; }

    public int DishesCreated { get; set; }

    public int DishesUpdated { get; set; }

    public int DishesSkipped { get; set; }

    public int DishesFailed { get; set; }

    public int ImagesFetched { get; set; }

    public int ImagesSkipped { get; set; }

    public int ImagesFallback { get; set; }

    public int ImagesFailed { get; set; }

    public List<string> Errors { get; } = [];

    public void PrintSummary()
    {
        Console.WriteLine();
        Console.WriteLine("=== Marketplace seed report ===");
        Console.WriteLine($"Partners  created={PartnersCreated} updated={PartnersUpdated} skipped={PartnersSkipped} failed={PartnersFailed}");
        Console.WriteLine($"Dishes    created={DishesCreated} updated={DishesUpdated} skipped={DishesSkipped} failed={DishesFailed}");
        Console.WriteLine($"Images    fetched={ImagesFetched} skipped={ImagesSkipped} fallback={ImagesFallback} failed={ImagesFailed}");

        if (Errors.Count > 0)
        {
            Console.WriteLine();
            Console.WriteLine("Errors:");
            foreach (var error in Errors)
                Console.WriteLine($"  - {error}");
        }
    }
}
