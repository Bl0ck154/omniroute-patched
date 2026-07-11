import { spawn } from "node:child_process";
import { mkdtemp, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { chromium } from "playwright";
import { SignJWT } from "jose";

const packageRoot = path.resolve(process.argv[2] || "");
if (!packageRoot) throw new Error("usage: packaged-smoke.mjs /path/to/installed/omniroute");

const port = Number(process.env.PATCHED_SMOKE_PORT || 20228);
const origin = `http://127.0.0.1:${port}`;
const dataDir = await mkdtemp(path.join(os.tmpdir(), "omniroute-patched-smoke-"));
const jwtSecret = "ci-jwt-secret-0123456789-abcdefghijklmnopqrstuvwxyz-ABCDEFGHIJ";
const apiSecret = "ci-api-secret-0123456789-abcdefghijklmnopqrstuvwxyz-ABCDEFGHIJ";
const child = spawn(process.execPath, [path.join(packageRoot, "bin/omniroute.mjs"), "--port", String(port), "--no-open"], {
  cwd: packageRoot,
  stdio: ["ignore", "pipe", "pipe"],
  env: {
    ...process.env,
    NODE_ENV: "production",
    HOST: "127.0.0.1",
    PORT: String(port),
    DATA_DIR: dataDir,
    JWT_SECRET: jwtSecret,
    API_KEY_SECRET: apiSecret,
    INITIAL_PASSWORD: "ci-only-password",
    REQUIRE_API_KEY: "true",
    AUTH_COOKIE_SECURE: "false",
    OMNIROUTE_DISABLE_BACKGROUND_SERVICES: "true",
    DISABLE_SQLITE_AUTO_BACKUP: "true",
    NEXT_TELEMETRY_DISABLED: "1"
  }
});

let logs = "";
child.stdout.on("data", (chunk) => (logs += chunk.toString()));
child.stderr.on("data", (chunk) => (logs += chunk.toString()));

async function waitForServer() {
  for (let attempt = 0; attempt < 120; attempt += 1) {
    if (child.exitCode !== null) throw new Error(`OmniRoute exited early (${child.exitCode})\n${logs}`);
    try {
      const response = await fetch(`${origin}/api/auth/status`);
      if (response.ok) return;
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  throw new Error(`OmniRoute did not become ready\n${logs}`);
}

let browser;
try {
  await waitForServer();

  const guard = await fetch(`${origin}/v1/models`);
  if (guard.status !== 401) throw new Error(`/v1/models expected 401, got ${guard.status}`);

  const token = await new SignJWT({ authenticated: true })
    .setProtectedHeader({ alg: "HS256" })
    .setExpirationTime("5m")
    .sign(new TextEncoder().encode(jwtSecret));

  browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  await context.addCookies([{ name: "auth_token", value: token, url: origin, httpOnly: true, sameSite: "Lax" }]);
  const page = await context.newPage();
  const pageErrors = [];
  const consoleErrors = [];
  page.on("pageerror", (error) => pageErrors.push(String(error)));
  page.on("console", (message) => {
    if (message.type() === "error") consoleErrors.push(message.text());
  });

  await page.route("**/api/settings", (route) => route.fulfill({ json: { autoRefreshProviderQuota: false } }));
  await page.route("**/api/providers/quota-windows", (route) => route.fulfill({ json: { defaults: { providerWindowDefaults: {}, globalThresholdPercent: 98 } } }));
  await page.route("**/api/providers/client", (route) => route.fulfill({
    json: {
      connections: [{
        id: "patched-smoke-codex",
        provider: "codex",
        name: "Patched Smoke",
        displayName: "Patched Smoke",
        authType: "oauth",
        isActive: true,
        priority: 1,
        providerSpecificData: { plan: "plus" }
      }]
    }
  }));
  await page.route("**/api/usage/provider-limits", (route) => route.fulfill({ json: { caches: {} } }));
  await page.route("**/api/usage/patched-smoke-codex", (route) => route.fulfill({ json: { quotas: [], plan: "plus" } }));

  const response = await page.goto(`${origin}/dashboard/quota`, { waitUntil: "networkidle", timeout: 90_000 });
  if (!response || response.status() !== 200) throw new Error(`quota page expected 200, got ${response?.status()}`);
  await page.locator('[data-omniroute-quota-ui-patch="source-v1"]').waitFor({ state: "visible", timeout: 30_000 });
  await page.getByText("Quota UI patch", { exact: true }).waitFor({ state: "visible", timeout: 30_000 });

  if (pageErrors.length) throw new Error(`page errors:\n${pageErrors.join("\n")}`);
  if (consoleErrors.length) throw new Error(`console errors:\n${consoleErrors.join("\n")}`);
  if (/TypeError|ReferenceError|Internal Server Error/.test(logs)) throw new Error(`runtime error in logs\n${logs}`);

  console.log("PACKAGED_LAUNCHER=ok");
  console.log("API_GUARD=ok");
  console.log("QUOTA_SSR=ok");
  console.log("QUOTA_HYDRATION=ok");
  console.log("BROWSER_CONSOLE=ok");
} finally {
  await browser?.close().catch(() => {});
  child.kill("SIGTERM");
  await new Promise((resolve) => {
    const timeout = setTimeout(resolve, 5000);
    child.once("exit", () => { clearTimeout(timeout); resolve(); });
  });
  if (child.exitCode === null) child.kill("SIGKILL");
  await rm(dataDir, { recursive: true, force: true });
}

