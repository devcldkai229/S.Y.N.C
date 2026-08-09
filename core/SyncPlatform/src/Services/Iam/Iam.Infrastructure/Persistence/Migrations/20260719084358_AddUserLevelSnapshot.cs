using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Iam.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddUserLevelSnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "user_level_snapshots",
                schema: "iam",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    computed_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    level_score = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: false),
                    tier = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    consistency_score = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: false),
                    progression_score = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: false),
                    recovery_capacity_score = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: false),
                    volume_load_weekly = table.Column<decimal>(type: "numeric(12,2)", precision: 12, scale: 2, nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    deleted_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_user_level_snapshots", x => x.id);
                    table.ForeignKey(
                        name: "fk_user_level_snapshots_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "iam",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_user_level_snapshots_user_id_computed_at",
                schema: "iam",
                table: "user_level_snapshots",
                columns: new[] { "user_id", "computed_at" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "user_level_snapshots",
                schema: "iam");
        }
    }
}
