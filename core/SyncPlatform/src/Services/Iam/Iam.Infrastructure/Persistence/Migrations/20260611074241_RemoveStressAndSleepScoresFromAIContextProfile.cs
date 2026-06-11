using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Iam.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class RemoveStressAndSleepScoresFromAIContextProfile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "sleep_quality_score",
                schema: "iam",
                table: "ai_context_profiles");

            migrationBuilder.DropColumn(
                name: "stress_score",
                schema: "iam",
                table: "ai_context_profiles");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "sleep_quality_score",
                schema: "iam",
                table: "ai_context_profiles",
                type: "numeric(6,4)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "stress_score",
                schema: "iam",
                table: "ai_context_profiles",
                type: "numeric(6,4)",
                nullable: false,
                defaultValue: 0m);
        }
    }
}
