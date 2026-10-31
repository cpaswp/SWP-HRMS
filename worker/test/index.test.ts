import { describe, expect, it } from "vitest";
import app, { isAllowedHrmsDatabase } from "../src/index";

const env = { APP_ENV: "test", HRMS_API_TOKEN: "a".repeat(48) };

describe("HRMS Worker database isolation", () => {
  it("allows only the dedicated test database outside production", () => {
    expect(isAllowedHrmsDatabase("swp_hrms_test", "test")).toBe(true);
    expect(isAllowedHrmsDatabase("swp-hrms", "test")).toBe(false);
    expect(isAllowedHrmsDatabase("swp_hrms_prod", "test")).toBe(false);
    expect(isAllowedHrmsDatabase("other_hrms", "development")).toBe(false);
  });

  it("allows only the separately named production database in production", () => {
    expect(isAllowedHrmsDatabase("swp_hrms_prod", "production")).toBe(true);
    expect(isAllowedHrmsDatabase("swp_hrms_test", "production")).toBe(false);
    expect(isAllowedHrmsDatabase("swp-hrms", "production")).toBe(false);
  });
});

describe("HRMS Worker security and health", () => {
  it("returns service health without touching ERP", async () => {
    const response = await app.request("/api/health", {}, env);
    expect(response.status).toBe(200);
    expect(response.headers.get("cache-control")).toContain("no-store");
    expect(response.headers.get("x-content-type-options")).toBe("nosniff");
    expect(await response.json()).toMatchObject({ status: "ok", service: "hrms-worker", database: "not-configured" });
  });

  it("rejects unauthenticated API requests", async () => {
    const response = await app.request("/api/v1/employees", {}, env);
    expect(response.status).toBe(401);
    expect(await response.json()).toEqual({ error: "unauthorized" });
  });

  it("rejects a weak/missing configured API token", async () => {
    const response = await app.request("/api/v1/departments", { headers: { Authorization: "Bearer " + "a".repeat(48) } }, { APP_ENV: "test" });
    expect(response.status).toBe(401);
  });

  it("requires authentication for attendance data", async () => {
    const response = await app.request("/api/v1/attendance?limit=50", { headers: { Authorization: "Bearer " + env.HRMS_API_TOKEN } }, env);
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ error: "database_not_configured" });
  });

  it("requires authentication for leave requests", async () => {
    const response = await app.request("/api/v1/leave-requests?limit=50", { headers: { Authorization: "Bearer " + env.HRMS_API_TOKEN } }, env);
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ error: "database_not_configured" });
  });

  it("rejects malformed and excessive pagination before querying the database", async () => {
    const invalidQueries = [
      "?limit=abc",
      "?limit=0",
      "?limit=101",
      "?offset=-1",
      "?offset=1000001",
      "?offset=1.5",
    ];
    for (const path of ["/api/v1/departments", "/api/v1/employees", "/api/v1/attendance", "/api/v1/leave-requests"]) {
      for (const query of invalidQueries) {
        const response = await app.request(path + query, {
          headers: { Authorization: "Bearer " + env.HRMS_API_TOKEN },
        }, env);
        expect(response.status, path + query).toBe(400);
        expect(await response.json()).toEqual({ error: "invalid_pagination" });
      }
    }
  });

  it("does not expose unknown routes", async () => {
    const response = await app.request("/unknown", {}, env);
    expect(response.status).toBe(404);
  });
});
