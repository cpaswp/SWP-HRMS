import { describe, expect, it } from "vitest";
import app from "../src/index";

const env = { APP_ENV: "test", HRMS_API_TOKEN: "a".repeat(48) };

describe("HRMS Worker security and health", () => {
  it("returns service health without touching ERP", async () => {
    const response = await app.request("/api/health", {}, env);
    expect(response.status).toBe(200);
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
    const response = await app.request("/api/v1/attendance", { headers: { Authorization: "Bearer " + env.HRMS_API_TOKEN } }, env);
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ error: "database_not_configured" });
  });

  it("requires authentication for leave requests", async () => {
    const response = await app.request("/api/v1/leave-requests", { headers: { Authorization: "Bearer " + env.HRMS_API_TOKEN } }, env);
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ error: "database_not_configured" });
  });

  it("does not expose unknown routes", async () => {
    const response = await app.request("/unknown", {}, env);
    expect(response.status).toBe(404);
  });
});
