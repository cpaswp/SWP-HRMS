import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const migrationsDir = path.resolve(here, "../migrations");
const files = (await readdir(migrationsDir))
  .filter((name) => /^\d{4}_[a-z0-9_]+\.sql$/.test(name))
  .sort();

const failures = [];
const createdTables = new Set();
const migrationVersions = new Map();
const migrationContents = [];

for (const file of files) {
  const source = await readFile(path.join(migrationsDir, file), "utf8");
  migrationContents.push({ file, source });
  const version = file.replace(/\.sql$/, "");
  const ledgerEntry = new RegExp("VALUES\\s*\\(\\s*['\"]" + version + "['\"]\\s*\\)", "gi");
  const ledgerMatches = [...source.matchAll(ledgerEntry)];
  if (ledgerMatches.length !== 1) {
    failures.push(`${file}: expected exactly one ledger entry for ${version}; found ${ledgerMatches.length}`);
  }
  const firstStatement = source.replace(/^(?:\\s+|--[^\\n]*(?:\\n|$))*/, "");
  if (!firstStatement.toUpperCase().startsWith("BEGIN;")) {
    failures.push(`${file}: migration must begin with BEGIN;`);
  }
  if (!source.trimEnd().toUpperCase().endsWith("COMMIT;")) {
    failures.push(`${file}: migration must end with COMMIT;`);
  }
  if (migrationVersions.has(version)) {
    failures.push(`${file}: duplicate migration version ${version}`);
  }
  migrationVersions.set(version, file);
  for (const match of source.matchAll(/CREATE TABLE IF NOT EXISTS\s+([a-zA-Z_][a-zA-Z0-9_]*)/gi)) {
    const table = match[1].toLowerCase();
    if (!table.startsWith("hrms_")) failures.push(`${file}: non-HRMS table declaration ${table}`);
    createdTables.add(table);
  }
  for (const match of source.matchAll(/^\s*(?:CREATE|ALTER|DROP)\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([a-zA-Z_][a-zA-Z0-9_]*)/gim)) {
    const table = match[1].toLowerCase();
    if (!table.startsWith("hrms_")) failures.push(`${file}: unprefixed table DDL target ${table}`);
  }
}

if (files.length === 0) failures.push("No numbered SQL migrations found.");
if (files.length > 0 && files[0].slice(0, 4) !== "0001") {
  failures.push(`First migration must start at 0001; found ${files[0]}`);
}
for (const { file, source } of migrationContents) {
  for (const match of source.matchAll(/^\s*ALTER TABLE\s+([a-zA-Z_][a-zA-Z0-9_]*)/gim)) {
    const table = match[1].toLowerCase();
    if (!createdTables.has(table)) failures.push(`${file}: ALTER target ${table} is not created by any migration`);
  }
}
for (let i = 1; i < files.length; i++) {
  const prev = Number(files[i - 1].slice(0, 4));
  const current = Number(files[i].slice(0, 4));
  if (current !== prev + 1) failures.push(`Migration numbering gap between ${files[i - 1]} and ${files[i]}`);
}

if (failures.length) {
  console.error("Migration static validation failed:");
  for (const failure of failures) console.error(` - ${failure}`);
  process.exit(1);
}

console.log(`Validated ${files.length} ordered HRMS migrations and ${createdTables.size} HRMS table declarations.`);
console.log("All ALTER TABLE targets exist in the migration set; all migration ledger entries and HRMS table prefixes passed.");
console.log("Note: static validation does not replace executing migrations against an isolated PostgreSQL test database.");
