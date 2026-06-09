using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Iam.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddLastActivityDateToGamificationProfile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "last_activity_date",
                schema: "iam",
                table: "gamification_profiles",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "last_activity_date",
                schema: "iam",
                table: "gamification_profiles");
        }
    }
}
