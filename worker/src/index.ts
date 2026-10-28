import { Hono } from "hono";
import postgres from "postgres";

export type Env = {
  APP_ENV?: string;
  HRMS_API_TOKEN?: string;
  HRMS_DATABASE_URL?: string;
  HRMS_DB?: { connectionString: string };
};

type Sql = ReturnType<typeof postgres>;

export function createApp(dbFactory: (env: Env) => Sql | null = createDatabase) {
  const app = new Hono<{ Bindings: Env }>();

  app.get("/api/health", async (c) => {
    const db = dbFactory(c.env);
    if (!db) return c.json({ status: "ok", service: "hrms-worker", database: "not-configured" });
    try {
      await db`SELECT 1`;
      return c.json({ status: "ok", service: "hrms-worker", database: "ok" });
    } catch {
      return c.json({ status: "error", service: "hrms-worker", database: "unavailable" }, 503);
    } finally {
      await db.end({ timeout: 1 }).catch(() => undefined);
    }
  });

  app.use("/api/v1/*", async (c, next) => {
    const expected = c.env.HRMS_API_TOKEN;
    const supplied = c.req.header("authorization")?.replace(/^Bearer\s+/i, "");
    if (!expected || expected.length < 32 || !supplied || !constantTimeEqual(supplied, expected)) {
      return c.json({ error: "unauthorized" }, 401);
    }
    await next();
  });

  app.get("/api/v1/departments", async (c) => {
    const db = dbFactory(c.env);
    if (!db) return c.json({ error: "database_not_configured" }, 503);
    try {
      const rows = await db`SELECT id, code, name, parent_id, is_active FROM hrms_departments ORDER BY name LIMIT 500`;
      return c.json({ data: rows });
    } catch {
      return c.json({ error: "database_unavailable" }, 503);
    } finally {
      await db.end({ timeout: 1 }).catch(() => undefined);
    }
  });

  app.get("/api/v1/employees", async (c) => {
    const db = dbFactory(c.env);
    if (!db) return c.json({ error: "database_not_configured" }, 503);
    const limit = Math.min(Math.max(Number(c.req.query("limit") ?? 50) || 50, 1), 100);
    const offset = Math.max(Number(c.req.query("offset") ?? 0) || 0, 0);
    try {
      const rows = await db`
        SELECT id, employee_code, full_name, email, phone, department_id, position_id, status, hire_date
        FROM hrms_employees ORDER BY employee_code LIMIT ${limit} OFFSET ${offset}
      `;
      return c.json({ data: rows, pagination: { limit, offset } });
    } catch {
      return c.json({ error: "database_unavailable" }, 503);
    } finally {
      await db.end({ timeout: 1 }).catch(() => undefined);
    }
  });

  app.notFound((c) => c.json({ error: "not_found" }, 404));
  app.onError((_error, c) => c.json({ error: "internal_error" }, 500));
  return app;
}

function createDatabase(env: Env): Sql | null {
  // Hyperdrive is preferred for deployed Worker -> PostgreSQL connectivity.
  const connectionString = env.HRMS_DB?.connectionString ?? env.HRMS_DATABASE_URL;
  if (!connectionString) return null;
  // Guard against accidentally configuring the ERP database by requiring an explicit
  // HRMS database name. Production provisioning must use a distinct database/project.
  const databaseName = (() => {
    try { return new URL(connectionString).pathname.replace(/^\//, ""); } catch { return ""; }
  })();
  if (!databaseName.toLowerCase().includes("hrms")) {
    throw new Error("HRMS database name must include 'hrms'; refusing a potentially shared ERP database.");
  }
  return postgres(connectionString, { max: 1, idle_timeout: 5, connect_timeout: 5, ssl: "require" });
}

function constantTimeEqual(a: string, b: string): boolean {
  let mismatch = a.length ^ b.length;
  const length = Math.max(a.length, b.length);
  for (let i = 0; i < length; i++) mismatch |= (a.charCodeAt(i) || 0) ^ (b.charCodeAt(i) || 0);
  return mismatch === 0;
}

export default createApp();
