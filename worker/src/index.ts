import { Hono } from "hono";
import postgres from "postgres";

export type Env = {
  APP_ENV?: string;
  HRMS_API_TOKEN?: string;
  HRMS_DATABASE_URL?: string;
  HRMS_DB?: { connectionString: string };
};

type Sql = ReturnType<typeof postgres>;

export function isAllowedHrmsDatabase(databaseName: string, appEnv = "development"): boolean {
  const expectedDatabase = appEnv === "production" ? "swp_hrms_prod" : "swp_hrms_test";
  return databaseName === expectedDatabase;
}

export function createApp(dbFactory: (env: Env) => Sql | null = createDatabase) {
  const app = new Hono<{ Bindings: Env }>();

  app.use("/api/*", async (c, next) => {
    await next();
    c.header("Cache-Control", "no-store, private");
    c.header("Pragma", "no-cache");
    c.header("X-Content-Type-Options", "nosniff");
    c.header("Referrer-Policy", "no-referrer");
    c.header("X-Frame-Options", "DENY");
  });

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
    const supplied = c.req.header("authorization")?.replace(/^Bearer\\s+/i, "");
    if (!expected || expected.length < 32 || !supplied || !constantTimeEqual(supplied, expected)) {
      return c.json({ error: "unauthorized" }, 401);
    }
    await next();
  });

  app.get("/api/v1/departments", async (c) => {
    const pagination = parsePagination(c.req.query("limit"), c.req.query("offset"));
    if (!pagination) return c.json({ error: "invalid_pagination" }, 400);
    const { limit, offset } = pagination;
    const db = dbFactory(c.env);
    if (!db) return c.json({ error: "database_not_configured" }, 503);
    try {
      const rows = await db`SELECT id, code, name, parent_id, is_active FROM hrms_departments ORDER BY name LIMIT ${limit} OFFSET ${offset}`;
      return c.json({ data: rows, pagination: { limit, offset } });
    } catch {
      return c.json({ error: "database_unavailable" }, 503);
    } finally {
      await db.end({ timeout: 1 }).catch(() => undefined);
    }
  });

  app.get("/api/v1/employees", async (c) => {
    const pagination = parsePagination(c.req.query("limit"), c.req.query("offset"));
    if (!pagination) return c.json({ error: "invalid_pagination" }, 400);
    const { limit, offset } = pagination;
    const db = dbFactory(c.env);
    if (!db) return c.json({ error: "database_not_configured" }, 503);
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

  app.get("/api/v1/attendance", async (c) => {
    const pagination = parsePagination(c.req.query("limit"), c.req.query("offset"));
    if (!pagination) return c.json({ error: "invalid_pagination" }, 400);
    const { limit, offset } = pagination;
    const db = dbFactory(c.env);
    if (!db) return c.json({ error: "database_not_configured" }, 503);
    try {
      const rows = await db`
        SELECT id, employee_id, site_id, kind, recorded_at, latitude, longitude, distance_meters
        FROM hrms_attendance_records
        ORDER BY recorded_at DESC
        LIMIT ${limit} OFFSET ${offset}
      `;
      return c.json({ data: rows, pagination: { limit, offset } });
    } catch {
      return c.json({ error: "database_unavailable" }, 503);
    } finally {
      await db.end({ timeout: 1 }).catch(() => undefined);
    }
  });

  app.get("/api/v1/leave-requests", async (c) => {
    const pagination = parsePagination(c.req.query("limit"), c.req.query("offset"));
    if (!pagination) return c.json({ error: "invalid_pagination" }, 400);
    const { limit, offset } = pagination;
    const db = dbFactory(c.env);
    if (!db) return c.json({ error: "database_not_configured" }, 503);
    try {
      const rows = await db`
        SELECT id, employee_id, leave_type, start_date, end_date, status, created_at
        FROM hrms_leave_requests
        ORDER BY created_at DESC
        LIMIT ${limit} OFFSET ${offset}
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

function parsePagination(limitRaw?: string, offsetRaw?: string): { limit: number; offset: number } | null {
  const limitText = limitRaw ?? "50";
  const offsetText = offsetRaw ?? "0";
  if (!/^\\d+$/.test(limitText) || !/^\\d+$/.test(offsetText)) return null;
  const limit = Number(limitText);
  const offset = Number(offsetText);
  if (!Number.isSafeInteger(limit) || limit < 1 || limit > 100) return null;
  if (!Number.isSafeInteger(offset) || offset < 0 || offset > 1_000_000) return null;
  return { limit, offset };
}

function createDatabase(env: Env): Sql | null {
  // Hyperdrive is preferred for deployed Worker -> PostgreSQL connectivity.
  const connectionString = env.HRMS_DB?.connectionString ?? env.HRMS_DATABASE_URL;
  if (!connectionString) return null;
  let databaseName = "";
  try {
    databaseName = decodeURIComponent(new URL(connectionString).pathname.replace(/^\\//, ""));
  } catch {
    throw new Error("HRMS database connection must be a valid PostgreSQL URL.");
  }
  if (!isAllowedHrmsDatabase(databaseName, env.APP_ENV)) {
    throw new Error("Refusing database connection: test/dev must use swp_hrms_test and production must use swp_hrms_prod.");
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
