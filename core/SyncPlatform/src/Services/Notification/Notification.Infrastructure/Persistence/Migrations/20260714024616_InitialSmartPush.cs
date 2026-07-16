using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Notification.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class InitialSmartPush : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "smart_push");

            migrationBuilder.CreateTable(
                name: "smart_push_log",
                schema: "smart_push",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    sent_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    local_date = table.Column<DateOnly>(type: "date", nullable: false),
                    trigger = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    dedup_key = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                    channel = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                    title = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                    body = table.Column<string>(type: "character varying(280)", maxLength: 280, nullable: true),
                    opened = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_smart_push_log", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "smart_push_schedule",
                schema: "smart_push",
                columns: table => new
                {
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    enabled = table.Column<bool>(type: "boolean", nullable: false),
                    timezone = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    next_fire_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    slots_per_day = table.Column<short>(type: "smallint", nullable: false),
                    sent_today = table.Column<short>(type: "smallint", nullable: false),
                    day_key_local = table.Column<DateOnly>(type: "date", nullable: true),
                    last_sent_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    last_trigger = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_smart_push_schedule", x => x.user_id);
                });

            migrationBuilder.CreateIndex(
                name: "ix_sps_log_user_date",
                schema: "smart_push",
                table: "smart_push_log",
                columns: new[] { "user_id", "local_date" });

            migrationBuilder.CreateIndex(
                name: "ux_sps_log_dedup",
                schema: "smart_push",
                table: "smart_push_log",
                column: "dedup_key",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_sps_due",
                schema: "smart_push",
                table: "smart_push_schedule",
                column: "next_fire_at_utc",
                filter: "enabled = true AND next_fire_at_utc IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "smart_push_log",
                schema: "smart_push");

            migrationBuilder.DropTable(
                name: "smart_push_schedule",
                schema: "smart_push");
        }
    }
}
