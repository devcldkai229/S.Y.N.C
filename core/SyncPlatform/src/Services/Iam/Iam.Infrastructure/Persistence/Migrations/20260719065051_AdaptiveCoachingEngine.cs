using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Iam.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AdaptiveCoachingEngine : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "daily_calorie_target",
                schema: "iam",
                table: "biometric_profiles",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "targets_adjusted_at_utc",
                schema: "iam",
                table: "biometric_profiles",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "targets_managed_by_engine",
                schema: "iam",
                table: "biometric_profiles",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "biometric_history",
                schema: "iam",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    recorded_at_utc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    weight_kg = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: false),
                    body_fat_percentage = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: true),
                    muscle_mass_kg = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: true),
                    source = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    note = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    deleted_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_biometric_history", x => x.id);
                    table.ForeignKey(
                        name: "fk_biometric_history_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "iam",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "target_adjustment_logs",
                schema: "iam",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    trigger = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    prev_calories = table.Column<int>(type: "integer", nullable: true),
                    new_calories = table.Column<int>(type: "integer", nullable: false),
                    prev_protein_gram = table.Column<int>(type: "integer", nullable: true),
                    prev_carb_gram = table.Column<int>(type: "integer", nullable: true),
                    prev_fat_gram = table.Column<int>(type: "integer", nullable: true),
                    new_protein_gram = table.Column<int>(type: "integer", nullable: false),
                    new_carb_gram = table.Column<int>(type: "integer", nullable: false),
                    new_fat_gram = table.Column<int>(type: "integer", nullable: false),
                    estimated_tdee = table.Column<int>(type: "integer", nullable: false),
                    formula_tdee = table.Column<int>(type: "integer", nullable: false),
                    confidence_level = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    reason_code = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    reason_text = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    applied_mode = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
                    roadmap_changed = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    deleted_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_target_adjustment_logs", x => x.id);
                    table.ForeignKey(
                        name: "fk_target_adjustment_logs_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "iam",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_biometric_history_user_id_recorded_at_utc",
                schema: "iam",
                table: "biometric_history",
                columns: new[] { "user_id", "recorded_at_utc" });

            migrationBuilder.CreateIndex(
                name: "ix_target_adjustment_logs_user_id_created_at",
                schema: "iam",
                table: "target_adjustment_logs",
                columns: new[] { "user_id", "created_at" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "biometric_history",
                schema: "iam");

            migrationBuilder.DropTable(
                name: "target_adjustment_logs",
                schema: "iam");

            migrationBuilder.DropColumn(
                name: "daily_calorie_target",
                schema: "iam",
                table: "biometric_profiles");

            migrationBuilder.DropColumn(
                name: "targets_adjusted_at_utc",
                schema: "iam",
                table: "biometric_profiles");

            migrationBuilder.DropColumn(
                name: "targets_managed_by_engine",
                schema: "iam",
                table: "biometric_profiles");
        }
    }
}
