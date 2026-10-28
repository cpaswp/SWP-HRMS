import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import postgres from "postgres";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const migrationsDir = path.join(here, "migrations");
const connectionString = process.env.HRMS_DATABASE_URL;

if (!connectionString) {
  console.error("Missing HRMS_DATABASE_URL. Set it only for a dedicated HRMS database.");
  process.exit(1);
}

let databaseName = "";
try {
  const parsed = new URL(connectionString);
  databaseName = decodeURIComponent(parsed.pathname.replace(/^\//, ""));
} catch {
  console.error("HRMS_DATABASE_URL is not a valid PostgreSQL URL.");
  process.exit(1);
}

if (!databaseName.toLowerCase().includes("hrms") || databaseName.toLowerCase().includes("erp")) {
  console.error("Refusing migration: database name must include 'hrms' and must not include 'erp'.");
  process.exit(1);
}

const files = (await readdir(migrationsDir))
  .filter((name) => /^\d{4}_[a-z0-9_]+\.sql$/.test(name))
  .sort();

if (files.length === 0) {
  console.error("No numbered SQL migrations found.");
  process.exit(1);
}

const sql = postgres(connectionString, {
  max: 1,
  idle_timeout: 5,
  connect_timeout: 10,
  ssl: "require",
  onnotice: () => {},
});

try {
  const identity = await sql`SELECT current_database() AS database_name, current_user AS database_user`;
  const actualName = String(identity[0]?.database_name ?? "");
  if (actualName !== databaseName) {
    throw new Error("Connected database name does not match the URL database name.");
  }
  if (!actualName.toLowerCase().includes("hrms") || actualName.toLowerCase().includes("erp")) {
    throw new Error("Connection safety check failed; refusing to run migrations.");
  }

  for (const file of files) {
    const version = file.replace(/\.sql$/, "");
    const exists = await sql`
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = 'hrms_schema_migrations'
    `;
    if (file !== "0001_hrms_core.sql" && exists.length === 0) {
      throw new Error("Migration ledger is missing; run 0001_hrms_core.sql first.");
    }
    if (exists.length > 0) {
      const applied = await sql`SELECT 1 FROM hrms_schema_migrations WHERE version = ${version} LIMIT 1`;
      if (applied.length > 0) {
        console.log(`SKIP ${file} (already recorded)`);
        continue;
      }
    }

    const contents = await readFile(path.join(migrationsDir, file), "utf8");
    console.log(`APPLY ${file}`);
    // Each migration owns its transaction and records its version atomically.
    await sql.unsafe(contents);
    const recorded = await sql`SELECT 1 FROM hrms_schema_migrations WHERE version = ${version} LIMIT 1`;
    if (recorded.length === 0) {
      throw new Error(`Migration ${file} did not record version ${version}.`);
    }
    console.log(`OK ${file}`);
  }
  console.log(`All migrations applied to dedicated database: ${databaseName}`);
} catch (error) {
  console.error("Migration failed:", error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
} finally {
  await sql.end({ timeout: 5 });
}
