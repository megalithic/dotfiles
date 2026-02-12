// subscription-fallback (pi extension)
//
// v2 UX goals:
// - support multiple vendors (openai, claude)
// - support multiple auth routes per vendor (oauth + api_key)
// - failover order is defined by a global preference stack (route + optional model)
// - model policy defaults to "follow_current", with optional per-stack-entry model override
// - expose a command UX + LLM-callable tool bridge

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import {
  getModels,
  loginAnthropic,
  loginOpenAICodex,
  refreshAnthropicToken,
  refreshOpenAICodexToken,
} from "@mariozechner/pi-ai";
import { Type } from "@sinclair/typebox";

type InputSource = "interactive" | "rpc" | "extension";
type AuthType = "oauth" | "api_key";
type FailoverScope = "global" | "current_vendor";

const EXT = "subscription-fallback";

interface PreferenceStackEntryConfig {
  route_id?: string;
  model?: string;
}

interface FailoverReturnConfig {
  enabled?: boolean;
  min_stable_minutes?: number;
}

interface FailoverTriggersConfig {
  rate_limit?: boolean;
  quota_exhausted?: boolean;
  auth_error?: boolean;
}

interface FailoverConfig {
  scope?: FailoverScope;
  return_to_preferred?: FailoverReturnConfig;
  // Legacy aliases accepted for compatibility.
  auto_return?: boolean;
  min_stable_minutes?: number;
  triggers?: FailoverTriggersConfig;
}

interface RouteConfig {
  id?: string;
  auth_type?: AuthType;
  label?: string;
  provider_id?: string;

  // API-key route material (prefer env/path over inline key)
  api_key_env?: string;
  api_key_path?: string;
  api_key?: string;

  // OpenAI optional per-route org/project env names
  openai_org_id_env?: string;
  openai_project_id_env?: string;

  // Optional per-route cooldown override
  cooldown_minutes?: number;
}

interface VendorConfig {
  vendor?: string;
  routes?: RouteConfig[];

  // Optional per-vendor defaults
  oauth_cooldown_minutes?: number;
  api_key_cooldown_minutes?: number;
  auto_retry?: boolean;
}

interface Config {
  enabled?: boolean;
  default_vendor?: string;
  vendors?: VendorConfig[];
  rate_limit_patterns?: string[];
  failover?: FailoverConfig;
  preference_stack?: PreferenceStackEntryConfig[];
}

interface NormalizedRoute {
  id: string;
  auth_type: AuthType;
  label: string;
  provider_id: string;
  api_key_env?: string;
  api_key_path?: string;
  api_key?: string;
  openai_org_id_env?: string;
  openai_project_id_env?: string;
  cooldown_minutes?: number;
}

interface NormalizedVendor {
  vendor: string;
  routes: NormalizedRoute[];
  oauth_cooldown_minutes: number;
  api_key_cooldown_minutes: number;
  auto_retry: boolean;
}

interface NormalizedPreferenceStackEntry {
  route_id: string;
  model?: string;
}

interface NormalizedFailoverReturnConfig {
  enabled: boolean;
  min_stable_minutes: number;
}

interface NormalizedFailoverTriggersConfig {
  rate_limit: boolean;
  quota_exhausted: boolean;
  auth_error: boolean;
}

interface NormalizedFailoverConfig {
  scope: FailoverScope;
  return_to_preferred: NormalizedFailoverReturnConfig;
  triggers: NormalizedFailoverTriggersConfig;
}

interface NormalizedConfig {
  enabled: boolean;
  default_vendor: string;
  vendors: NormalizedVendor[];
  rate_limit_patterns: string[];
  failover: NormalizedFailoverConfig;
  preference_stack: NormalizedPreferenceStackEntry[];
}

interface ResolvedRouteRef {
  vendor: string;
  index: number;
  route: NormalizedRoute;
}

interface EffectivePreferenceEntry {
  stack_index: number;
  route_ref: ResolvedRouteRef;
  model_id: string;
  model_source: "entry" | "current";
}

// Legacy schema from v1 (OpenAI-only)
interface LegacyOpenAIAccount {
  name?: string;
  apiKeyEnv?: string;
  apiKeyPath?: string;
  apiKey?: string;
  openaiOrgIdEnv?: string;
  openaiProjectIdEnv?: string;
}

interface LegacyConfig {
  enabled?: boolean;
  primaryProvider?: string;
  primaryProviders?: string[];
  fallbackProvider?: string;
  modelId?: string;
  cooldownMinutes?: number;
  autoRetry?: boolean;
  rateLimitPatterns?: string[];
  fallbackAccounts?: LegacyOpenAIAccount[];
  fallbackAccountCooldownMinutes?: number;
}

interface LastPrompt {
  source: InputSource;
  text: string;
  images: any[];
}

interface OriginalEnv {
  openai_api_key?: string;
  openai_org_id?: string;
  openai_project_id?: string;
  anthropic_api_key?: string;
}

interface PersistedState {
  version?: number;
  route_cooldown_until?: Record<string, number>;
  next_return_eligible_at_ms?: number;
}

interface RouteProbeResult {
  ok: boolean;
  message?: string;
  retry_after_ms?: number;
}

const decode = (s: string): string => {
  try {
    return decodeURIComponent(s);
  } catch {
    return s;
  }
};

function splitArgs(input: string): string[] {
  return input
    .trim()
    .split(/\s+/)
    .map((t) => t.trim())
    .filter(Boolean);
}

function slugify(s: string): string {
  return s
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/--+/g, "-")
    .slice(0, 64);
}

function titleCase(s: string): string {
  if (!s) return s;
  return s[0].toUpperCase() + s.slice(1);
}

function expandHome(path: string): string {
  if (!path) return path;
  if (path.startsWith("~/")) return join(homedir(), path.slice(2));
  return path;
}

function readJson(path: string): any | undefined {
  if (!existsSync(path)) return undefined;
  try {
    return JSON.parse(readFileSync(path, "utf-8"));
  } catch (e) {
    console.error(`[${EXT}] Failed to parse ${path}:`, e);
    return undefined;
  }
}

function writeJson(path: string, value: unknown): void {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, JSON.stringify(value, null, 2) + "\n", "utf-8");
}

function globalConfigPath(): string {
  return join(homedir(), ".pi", "agent", "subswitch.json");
}

function projectConfigPath(cwd: string): string {
  return join(cwd, ".pi", "subswitch.json");
}

function globalStatePath(): string {
  return join(homedir(), ".pi", "agent", "subswitch-state.json");
}

function projectStatePath(cwd: string): string {
  return join(cwd, ".pi", "subswitch-state.json");
}

function statePathForConfigPath(cwd: string, configPath: string): string {
  return configPath === projectConfigPath(cwd)
    ? projectStatePath(cwd)
    : globalStatePath();
}

function preferredWritableStatePath(cwd: string): string {
  return statePathForConfigPath(cwd, preferredWritableConfigPath(cwd));
}

function statePathCandidates(cwd: string): string[] {
  const preferred = preferredWritableStatePath(cwd);
  const fallback =
    preferred === projectStatePath(cwd)
      ? globalStatePath()
      : projectStatePath(cwd);
  return preferred === fallback ? [preferred] : [preferred, fallback];
}

function legacyGlobalConfigPath(): string {
  return join(homedir(), ".pi", "agent", "subscription-fallback.json");
}

function legacyProjectConfigPath(cwd: string): string {
  return join(cwd, ".pi", "subscription-fallback.json");
}

function defaultProviderId(vendor: string, authType: AuthType): string {
  const v = vendor.toLowerCase();
  if (v === "openai" && authType === "oauth") return "openai-codex";
  if (v === "openai" && authType === "api_key") return "openai";
  if ((v === "claude" || v === "anthropic") && authType === "oauth") return "anthropic";
  if ((v === "claude" || v === "anthropic") && authType === "api_key") return "anthropic-api";
  return v;
}

function routeDisplay(vendor: string, route: { auth_type: AuthType; label: string }): string {
  return `${vendor} · ${route.auth_type} · ${route.label}`;
}

function mergeVendorLists(globalVendors: VendorConfig[] | undefined, projectVendors: VendorConfig[] | undefined): VendorConfig[] {
  const g = Array.isArray(globalVendors) ? globalVendors : [];
  const p = Array.isArray(projectVendors) ? projectVendors : [];
  if (p.length === 0) return g;

  const byVendor = new Map<string, VendorConfig>();
  const globalOrder: string[] = [];
  for (const v of g) {
    const key = String(v.vendor ?? "").trim().toLowerCase();
    if (!key) continue;
    byVendor.set(key, v);
    globalOrder.push(key);
  }

  const projectOrder: string[] = [];
  for (const v of p) {
    const key = String(v.vendor ?? "").trim().toLowerCase();
    if (!key) continue;
    byVendor.set(key, v);
    projectOrder.push(key);
  }

  const out: VendorConfig[] = [];
  const seen = new Set<string>();

  for (const key of projectOrder) {
    const v = byVendor.get(key);
    if (!v) continue;
    out.push(v);
    seen.add(key);
  }

  for (const key of globalOrder) {
    if (seen.has(key)) continue;
    const v = byVendor.get(key);
    if (!v) continue;
    out.push(v);
  }

  return out;
}

function uniqueRouteId(base: string, usedIds: Set<string>): string {
  const cleaned = (base || "").trim().replace(/\s+/g, "-") || "route";
  if (!usedIds.has(cleaned)) {
    usedIds.add(cleaned);
    return cleaned;
  }

  let n = 2;
  while (usedIds.has(`${cleaned}-${n}`)) n += 1;
  const id = `${cleaned}-${n}`;
  usedIds.add(id);
  return id;
}

function normalizeRoute(
  vendor: string,
  route: RouteConfig,
  index: number,
  usedIds: Set<string>,
): NormalizedRoute | undefined {
  const authType: AuthType = route.auth_type === "oauth" || route.auth_type === "api_key" ? route.auth_type : "oauth";

  const providerId = String(route.provider_id ?? defaultProviderId(vendor, authType)).trim();
  if (!providerId) return undefined;

  const fallbackLabel = `${authType}-${index + 1}`;
  const label = String(route.label ?? fallbackLabel).trim() || fallbackLabel;
  const rawRouteId = String(route.id ?? `${vendor}-${authType}-${label}`).trim();
  const routeId = uniqueRouteId(rawRouteId, usedIds);

  const out: NormalizedRoute = {
    id: routeId,
    auth_type: authType,
    label,
    provider_id: providerId,
  };

  if (route.api_key_env) out.api_key_env = String(route.api_key_env).trim();
  if (route.api_key_path) out.api_key_path = String(route.api_key_path).trim();
  if (route.api_key) out.api_key = String(route.api_key).trim();
  if (route.openai_org_id_env) out.openai_org_id_env = String(route.openai_org_id_env).trim();
  if (route.openai_project_id_env)
    out.openai_project_id_env = String(route.openai_project_id_env).trim();

  if (route.cooldown_minutes !== undefined && Number.isFinite(Number(route.cooldown_minutes))) {
    const n = Math.max(1, Math.floor(Number(route.cooldown_minutes)));
    out.cooldown_minutes = n;
  }

  return out;
}

function normalizeFailover(raw: FailoverConfig | undefined): NormalizedFailoverConfig {
  const scope: FailoverScope = raw?.scope === "current_vendor" ? "current_vendor" : "global";

  const returnEnabled = raw?.return_to_preferred?.enabled ?? raw?.auto_return ?? true;
  const minStableMinutesRaw =
    raw?.return_to_preferred?.min_stable_minutes ?? raw?.min_stable_minutes ?? 10;
  const minStableMinutes = Number.isFinite(Number(minStableMinutesRaw))
    ? Math.max(0, Math.floor(Number(minStableMinutesRaw)))
    : 10;

  return {
    scope,
    return_to_preferred: {
      enabled: Boolean(returnEnabled),
      min_stable_minutes: minStableMinutes,
    },
    triggers: {
      rate_limit: raw?.triggers?.rate_limit ?? true,
      quota_exhausted: raw?.triggers?.quota_exhausted ?? true,
      auth_error: raw?.triggers?.auth_error ?? true,
    },
  };
}

function buildDefaultPreferenceStack(
  vendors: NormalizedVendor[],
  defaultVendor: string,
): NormalizedPreferenceStackEntry[] {
  const vendorOrder: string[] = [];
  if (vendors.some((v) => v.vendor === defaultVendor)) {
    vendorOrder.push(defaultVendor);
  }
  for (const v of vendors) {
    if (!vendorOrder.includes(v.vendor)) vendorOrder.push(v.vendor);
  }

  const byVendor = new Map<string, NormalizedVendor>();
  for (const v of vendors) byVendor.set(v.vendor, v);

  const out: NormalizedPreferenceStackEntry[] = [];
  const pushByAuth = (authType: AuthType): void => {
    for (const vendor of vendorOrder) {
      const v = byVendor.get(vendor);
      if (!v) continue;
      for (const route of v.routes) {
        if (route.auth_type !== authType) continue;
        out.push({ route_id: route.id });
      }
    }
  };

  // Recommended default: subscription first, then API key routes.
  pushByAuth("oauth");
  pushByAuth("api_key");

  if (out.length === 0) {
    for (const v of vendors) {
      for (const route of v.routes) {
        out.push({ route_id: route.id });
      }
    }
  }

  return out;
}

function normalizePreferenceStack(
  inputEntries: PreferenceStackEntryConfig[] | undefined,
  vendors: NormalizedVendor[],
  defaultVendor: string,
): NormalizedPreferenceStackEntry[] {
  const routeIds = new Set<string>();
  for (const v of vendors) {
    for (const route of v.routes) routeIds.add(route.id);
  }

  const out: NormalizedPreferenceStackEntry[] = [];
  const seen = new Set<string>();
  const raw = Array.isArray(inputEntries) ? inputEntries : [];
  for (const entry of raw) {
    const routeId = String(entry?.route_id ?? "").trim();
    if (!routeId || !routeIds.has(routeId)) continue;

    const model = String(entry?.model ?? "").trim() || undefined;
    const key = `${routeId}::${model ?? ""}`;
    if (seen.has(key)) continue;

    out.push({ route_id: routeId, ...(model ? { model } : {}) });
    seen.add(key);
  }

  const recommended = buildDefaultPreferenceStack(vendors, defaultVendor);
  if (out.length === 0) return recommended;

  // Ensure every configured route appears at least once in the stack.
  const presentRouteIds = new Set(out.map((entry) => entry.route_id));
  for (const entry of recommended) {
    if (presentRouteIds.has(entry.route_id)) continue;
    out.push(entry);
    presentRouteIds.add(entry.route_id);
  }

  return out;
}

function normalizeConfig(input: Config | undefined): NormalizedConfig {
  const vendorsInput = Array.isArray(input?.vendors) ? input?.vendors : [];

  const vendors: NormalizedVendor[] = [];
  const usedRouteIds = new Set<string>();
  for (const rawVendor of vendorsInput) {
    const vendorName = String(rawVendor.vendor ?? "").trim().toLowerCase();
    if (!vendorName) continue;

    const rawRoutes = Array.isArray(rawVendor.routes) ? rawVendor.routes : [];
    const routes: NormalizedRoute[] = [];
    for (let i = 0; i < rawRoutes.length; i++) {
      const normalized = normalizeRoute(vendorName, rawRoutes[i], i, usedRouteIds);
      if (normalized) routes.push(normalized);
    }

    if (routes.length === 0) continue;

    const oauthCooldown = Number.isFinite(Number(rawVendor.oauth_cooldown_minutes))
      ? Math.max(1, Math.floor(Number(rawVendor.oauth_cooldown_minutes)))
      : 180;

    const apiCooldown = Number.isFinite(Number(rawVendor.api_key_cooldown_minutes))
      ? Math.max(1, Math.floor(Number(rawVendor.api_key_cooldown_minutes)))
      : 15;

    vendors.push({
      vendor: vendorName,
      routes,
      oauth_cooldown_minutes: oauthCooldown,
      api_key_cooldown_minutes: apiCooldown,
      auto_retry: rawVendor.auto_retry ?? true,
    });
  }

  let defaultVendor = String(input?.default_vendor ?? vendors[0]?.vendor ?? "openai")
    .trim()
    .toLowerCase();
  if (vendors.length > 0 && !vendors.some((v) => v.vendor === defaultVendor)) {
    defaultVendor = vendors[0].vendor;
  }

  const rateLimitPatterns = Array.isArray(input?.rate_limit_patterns)
    ? input?.rate_limit_patterns.map((p) => String(p).trim()).filter(Boolean)
    : [];

  const failover = normalizeFailover(input?.failover);
  const preferenceStack = normalizePreferenceStack(input?.preference_stack, vendors, defaultVendor);

  return {
    enabled: input?.enabled ?? true,
    default_vendor: defaultVendor,
    vendors,
    rate_limit_patterns: rateLimitPatterns,
    failover,
    preference_stack: preferenceStack,
  };
}

function migrateLegacyConfig(legacy: LegacyConfig | undefined): Config | undefined {
  if (!legacy) return undefined;

  const primaries = Array.isArray(legacy.primaryProviders)
    ? legacy.primaryProviders.map((p) => String(p).trim()).filter(Boolean)
    : [];
  const primaryProvider = String(legacy.primaryProvider ?? "openai-codex").trim();

  const oauthProviders = primaries.length > 0 ? primaries : primaryProvider ? [primaryProvider] : ["openai-codex"];

  const oauthRoutes: RouteConfig[] = oauthProviders.map((providerId) => {
    let label = providerId;
    if (providerId === "openai-codex") {
      label = "personal";
    } else if (providerId.startsWith("openai-codex-")) {
      label = providerId.slice("openai-codex-".length);
    }

    return {
      auth_type: "oauth",
      label,
      provider_id: providerId,
      cooldown_minutes: legacy.cooldownMinutes,
    };
  });

  const fallbackProvider = String(legacy.fallbackProvider ?? "openai").trim() || "openai";

  const fallbackAccounts = Array.isArray(legacy.fallbackAccounts) ? legacy.fallbackAccounts : [];
  const apiRoutes: RouteConfig[] = [];

  if (fallbackAccounts.length > 0) {
    for (let i = 0; i < fallbackAccounts.length; i++) {
      const a = fallbackAccounts[i];
      const label = String(a.name ?? `api-${i + 1}`).trim() || `api-${i + 1}`;
      apiRoutes.push({
        auth_type: "api_key",
        label,
        provider_id: fallbackProvider,
        api_key_env: a.apiKeyEnv,
        api_key_path: a.apiKeyPath,
        api_key: a.apiKey,
        openai_org_id_env: a.openaiOrgIdEnv,
        openai_project_id_env: a.openaiProjectIdEnv,
        cooldown_minutes: legacy.fallbackAccountCooldownMinutes,
      });
    }
  } else {
    apiRoutes.push({
      auth_type: "api_key",
      label: "default",
      provider_id: fallbackProvider,
      api_key_env: "OPENAI_API_KEY",
      cooldown_minutes: legacy.fallbackAccountCooldownMinutes,
    });
  }

  return {
    enabled: legacy.enabled ?? true,
    default_vendor: "openai",
    rate_limit_patterns: legacy.rateLimitPatterns ?? [],
    vendors: [
      {
        vendor: "openai",
        routes: [...oauthRoutes, ...apiRoutes],
        oauth_cooldown_minutes: legacy.cooldownMinutes ?? 180,
        api_key_cooldown_minutes: legacy.fallbackAccountCooldownMinutes ?? 15,
        auto_retry: legacy.autoRetry ?? true,
      },
    ],
  };
}

function loadConfig(cwd: string): NormalizedConfig {
  const globalPath = globalConfigPath();
  const projectPath = projectConfigPath(cwd);

  const globalCfg = readJson(globalPath) as Config | undefined;
  const projectCfg = readJson(projectPath) as Config | undefined;

  let merged: Config | undefined;

  if (globalCfg || projectCfg) {
    const base: Config = {
      enabled: true,
      default_vendor: "openai",
      vendors: [],
      rate_limit_patterns: [],
    };

    merged = {
      ...base,
      ...globalCfg,
      ...projectCfg,
      vendors: mergeVendorLists(globalCfg?.vendors, projectCfg?.vendors),
      rate_limit_patterns: projectCfg?.rate_limit_patterns ?? globalCfg?.rate_limit_patterns ?? [],
    };
  } else {
    const legacyGlobal = readJson(legacyGlobalConfigPath()) as LegacyConfig | undefined;
    const legacyProject = readJson(legacyProjectConfigPath(cwd)) as LegacyConfig | undefined;

    const migratedGlobal = migrateLegacyConfig(legacyGlobal);
    const migratedProject = migrateLegacyConfig(legacyProject);

    if (migratedGlobal || migratedProject) {
      merged = {
        enabled: true,
        default_vendor: "openai",
        vendors: mergeVendorLists(migratedGlobal?.vendors, migratedProject?.vendors),
        rate_limit_patterns:
          migratedProject?.rate_limit_patterns ?? migratedGlobal?.rate_limit_patterns ?? [],
      };
    }
  }

  const normalized = normalizeConfig(merged);

  if (normalized.vendors.length === 0) {
    // Safe bootstrap default: OpenAI subscription + OpenAI API key.
    return normalizeConfig({
      enabled: true,
      default_vendor: "openai",
      vendors: [
        {
          vendor: "openai",
          routes: [
            { auth_type: "oauth", label: "personal", provider_id: "openai-codex" },
            {
              auth_type: "api_key",
              label: "default",
              provider_id: "openai",
              api_key_env: "OPENAI_API_KEY",
            },
          ],
          oauth_cooldown_minutes: 180,
          api_key_cooldown_minutes: 15,
          auto_retry: true,
        },
      ],
      rate_limit_patterns: [],
    });
  }

  return normalized;
}

function configToJson(cfg: NormalizedConfig): Config {
  return {
    enabled: cfg.enabled,
    default_vendor: cfg.default_vendor,
    rate_limit_patterns: cfg.rate_limit_patterns,
    failover: {
      scope: cfg.failover.scope,
      return_to_preferred: {
        enabled: cfg.failover.return_to_preferred.enabled,
        min_stable_minutes: cfg.failover.return_to_preferred.min_stable_minutes,
      },
      triggers: {
        rate_limit: cfg.failover.triggers.rate_limit,
        quota_exhausted: cfg.failover.triggers.quota_exhausted,
        auth_error: cfg.failover.triggers.auth_error,
      },
    },
    preference_stack: cfg.preference_stack.map((entry) => ({
      route_id: entry.route_id,
      model: entry.model,
    })),
    vendors: cfg.vendors.map((v) => ({
      vendor: v.vendor,
      oauth_cooldown_minutes: v.oauth_cooldown_minutes,
      api_key_cooldown_minutes: v.api_key_cooldown_minutes,
      auto_retry: v.auto_retry,
      routes: v.routes.map((r) => ({
        id: r.id,
        auth_type: r.auth_type,
        label: r.label,
        provider_id: r.provider_id,
        api_key_env: r.api_key_env,
        api_key_path: r.api_key_path,
        api_key: r.api_key,
        openai_org_id_env: r.openai_org_id_env,
        openai_project_id_env: r.openai_project_id_env,
        cooldown_minutes: r.cooldown_minutes,
      })),
    })),
  };
}

function preferredWritableConfigPath(cwd: string): string {
  const project = projectConfigPath(cwd);
  const global = globalConfigPath();

  if (existsSync(project)) return project;

  const legacyProject = legacyProjectConfigPath(cwd);
  if (existsSync(legacyProject)) return project;

  if (existsSync(global)) return global;

  const legacyGlobal = legacyGlobalConfigPath();
  if (existsSync(legacyGlobal)) return global;

  return global;
}

function isContextWindowExceededError(err: unknown): boolean {
  const s = String(err ?? "");
  const l = s.toLowerCase();

  const patterns = [
    "context window",
    "context length",
    "maximum context",
    "maximum context length",
    "max context",
    "context_length_exceeded",
    "context length exceeded",
    "this model's maximum context length",
    "prompt is too long",
    "input is too long",
    "too many tokens",
  ];

  return patterns.some((p) => p && l.includes(p));
}

function isQuotaExhaustedError(err: unknown): boolean {
  if (isContextWindowExceededError(err)) return false;

  const s = String(err ?? "");
  const l = s.toLowerCase();

  const patterns = [
    "insufficient_quota",
    "quota exceeded",
    "exceeded your current quota",
    "billing hard limit",
    "credit balance",
    "out of credits",
  ];

  return patterns.some((p) => p && l.includes(p));
}

function isRateLimitSignalError(err: unknown, extraPatterns: string[] = []): boolean {
  if (isContextWindowExceededError(err)) return false;

  const s = String(err ?? "");
  const l = s.toLowerCase();

  const patterns = [
    "rate limit",
    "ratelimit",
    "too many requests",
    "429",
    "try again later",
    "please try again",
    "usage limit",
    "usage_limit",
    "capacity",
    ...extraPatterns.map((p) => p.toLowerCase()),
  ];

  return patterns.some((p) => p && l.includes(p));
}

function isAuthError(err: unknown): boolean {
  if (isContextWindowExceededError(err)) return false;

  const s = String(err ?? "");
  const l = s.toLowerCase();

  const patterns = [
    "invalid api key",
    "incorrect api key",
    "api key is not valid",
    "authentication",
    "unauthorized",
    "forbidden",
    "permission denied",
    "401",
    "403",
    "invalid x-api-key",
    "missing api key",
  ];

  return patterns.some((p) => p && l.includes(p));
}

function parseRetryAfterMs(err: unknown): number | undefined {
  const s = String(err ?? "");
  if (!s) return undefined;

  const resetsAt = s.match(/\bresets_at\b[^0-9]*(\d{9,13})/i);
  if (resetsAt) {
    const raw = Number(resetsAt[1]);
    if (!Number.isNaN(raw)) {
      const tsMs = resetsAt[1].length >= 13 ? raw : raw * 1000;
      const delta = tsMs - Date.now();
      if (delta > 0) return delta;
    }
  }

  const iso = s.match(/(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z)/);
  if (iso) {
    const ts = Date.parse(iso[1]);
    if (!Number.isNaN(ts)) {
      const delta = ts - Date.now();
      if (delta > 0) return delta;
    }
  }

  const tryAgainMin = s.match(/try again in\s*~?\s*(\d+)\s*(?:min|mins|minutes)\b/i);
  if (tryAgainMin) return Number(tryAgainMin[1]) * 60_000;

  const retryAfter = s.match(
    /retry[\s-]*after\s*(\d+)\s*(s|sec|secs|seconds|m|min|mins|minutes|h|hr|hrs|hours)\b/i,
  );
  if (retryAfter) {
    const n = Number(retryAfter[1]);
    const unit = retryAfter[2].toLowerCase();
    if (unit.startsWith("s")) return n * 1000;
    if (unit.startsWith("m")) return n * 60_000;
    if (unit.startsWith("h")) return n * 3_600_000;
  }

  const dur = s.match(/\bin\s*~?\s*(?:(\d+)\s*h)?\s*(?:(\d+)\s*m)?\s*(?:(\d+)\s*s)?\b/i);
  if (dur) {
    const h = dur[1] ? Number(dur[1]) : 0;
    const m = dur[2] ? Number(dur[2]) : 0;
    const sec = dur[3] ? Number(dur[3]) : 0;
    const total = h * 3_600_000 + m * 60_000 + sec * 1000;
    if (total > 0) return total;
  }

  const at = s.match(/again at\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b/i);
  if (at) {
    let hour = Number(at[1]);
    const minute = at[2] ? Number(at[2]) : 0;
    const ampm = at[3].toLowerCase();

    if (ampm === "pm" && hour < 12) hour += 12;
    if (ampm === "am" && hour === 12) hour = 0;

    const target = new Date(Date.now());
    target.setSeconds(0, 0);
    target.setHours(hour, minute, 0, 0);
    if (target.getTime() <= Date.now()) target.setDate(target.getDate() + 1);
    return target.getTime() - Date.now();
  }

  return undefined;
}

function cloneProviderModels(sourceProvider: string): any[] {
  const models = getModels(sourceProvider);
  if (!models) return [];
  return models.map((m) => ({
    id: m.id,
    name: m.name,
    api: m.api,
    reasoning: m.reasoning,
    input: m.input,
    cost: m.cost,
    contextWindow: m.contextWindow,
    maxTokens: m.maxTokens,
    headers: m.headers,
    compat: (m as any).compat,
  }));
}

function providerBaseUrl(sourceProvider: string): string | undefined {
  const models = getModels(sourceProvider);
  if (!models || models.length === 0) return undefined;
  return (models[0] as any).baseUrl;
}

export default function (pi: ExtensionAPI): void {
  let cfg: NormalizedConfig | undefined;

  let lastCtx: any | undefined;
  let lastPrompt: LastPrompt | undefined;
  let pendingInputSource: InputSource | undefined;

  // Current model selected by /model (used when preference stack entries omit model).
  let managedModelId: string | undefined;

  // Current route state
  let activeVendor: string | undefined;
  const activeRouteIndexByVendor = new Map<string, number>();

  // Per-route cooldown state. Key: route_id => epoch ms.
  const routeCooldownUntil = new Map<string, number>();

  // Persistent runtime state path (project or global, based on active config location).
  let statePath: string | undefined;

  // Retry timer for cooldown expiry checks
  let retryTimer: ReturnType<typeof setTimeout> | undefined;

  // Avoid feedback loops for extension-driven model changes.
  let pendingExtensionSwitch: { provider: string; modelId: string } | undefined;

  let originalEnv: OriginalEnv | undefined;

  // Keep track of aliases we registered to avoid duplicate work.
  const registeredAliases = new Set<string>();

  const LOGIN_WIDGET_KEY = `${EXT}-oauth-login`;
  let pendingOauthReminderProviders: string[] = [];

  // Prevent immediate bounce-backs after failover.
  let nextReturnEligibleAtMs = 0;

  const RETURN_PROBE_TIMEOUT_MS = 12_000;
  const RETURN_PROBE_MIN_COOLDOWN_MS = 2 * 60_000;
  const RETURN_PROBE_MAX_COOLDOWN_MS = 10 * 60_000;

  function now(): number {
    return Date.now();
  }

  function ensureCfg(ctx: any): NormalizedConfig {
    if (!cfg) {
      cfg = loadConfig(ctx.cwd);
      registerAliasesFromConfig(cfg);
      statePath = preferredWritableStatePath(ctx.cwd);
      pruneRuntimeState();
    }
    return cfg;
  }

  function reloadCfg(ctx: any): void {
    cfg = loadConfig(ctx.cwd);
    registerAliasesFromConfig(cfg);
    statePath = preferredWritableStatePath(ctx.cwd);
    pruneRuntimeState();
  }

  function getVendor(vendor: string): NormalizedVendor | undefined {
    if (!cfg) return undefined;
    const key = vendor.trim().toLowerCase();
    return cfg.vendors.find((v) => v.vendor === key);
  }

  function getRoute(vendor: string, index: number): NormalizedRoute | undefined {
    const v = getVendor(vendor);
    if (!v) return undefined;
    if (index < 0 || index >= v.routes.length) return undefined;
    return v.routes[index];
  }

  function resolveRouteById(routeId: string): ResolvedRouteRef | undefined {
    if (!cfg) return undefined;
    const id = routeId.trim();
    if (!id) return undefined;

    for (const v of cfg.vendors) {
      for (let i = 0; i < v.routes.length; i++) {
        if (v.routes[i].id === id) {
          return { vendor: v.vendor, index: i, route: v.routes[i] };
        }
      }
    }
    return undefined;
  }

  function routeStateKey(vendor: string, index: number): string | undefined {
    const route = getRoute(vendor, index);
    return route?.id;
  }

  function pruneRuntimeState(): void {
    const currentTs = now();

    const validRouteIds = new Set<string>();
    if (cfg) {
      for (const v of cfg.vendors) {
        for (const route of v.routes) validRouteIds.add(route.id);
      }
    }

    for (const [routeId, until] of routeCooldownUntil.entries()) {
      if (!Number.isFinite(until) || until <= currentTs) {
        routeCooldownUntil.delete(routeId);
        continue;
      }

      if (validRouteIds.size > 0 && !validRouteIds.has(routeId)) {
        routeCooldownUntil.delete(routeId);
      }
    }

    if (!cfg?.failover.return_to_preferred.enabled || nextReturnEligibleAtMs <= currentTs) {
      nextReturnEligibleAtMs = 0;
    }
  }

  function buildPersistedState(): PersistedState {
    pruneRuntimeState();

    const routeCooldowns: Record<string, number> = {};
    for (const [routeId, until] of routeCooldownUntil.entries()) {
      routeCooldowns[routeId] = Math.floor(until);
    }

    const state: PersistedState = { version: 1 };
    if (Object.keys(routeCooldowns).length > 0) {
      state.route_cooldown_until = routeCooldowns;
    }

    if (nextReturnEligibleAtMs > now()) {
      state.next_return_eligible_at_ms = Math.floor(nextReturnEligibleAtMs);
    }

    return state;
  }

  function persistRuntimeState(): void {
    if (!statePath) return;
    writeJson(statePath, buildPersistedState());
  }

  function loadRuntimeState(ctx: any): void {
    ensureCfg(ctx);
    statePath = preferredWritableStatePath(ctx.cwd);

    routeCooldownUntil.clear();
    nextReturnEligibleAtMs = 0;

    const candidates = statePathCandidates(ctx.cwd);
    for (const candidate of candidates) {
      const raw = readJson(candidate) as PersistedState | undefined;
      if (!raw) continue;

      const routeCooldowns = raw.route_cooldown_until;
      if (routeCooldowns && typeof routeCooldowns === "object") {
        for (const [routeId, untilRaw] of Object.entries(routeCooldowns)) {
          if (!routeId) continue;
          const until = Number(untilRaw);
          if (!Number.isFinite(until) || until <= now()) continue;
          routeCooldownUntil.set(routeId, Math.floor(until));
        }
      }

      const holdoff = Number(raw.next_return_eligible_at_ms);
      if (Number.isFinite(holdoff) && holdoff > now()) {
        nextReturnEligibleAtMs = Math.floor(holdoff);
      }

      break;
    }

    pruneRuntimeState();
    persistRuntimeState();
  }

  function setNextReturnEligibleAtMs(untilMs: number): void {
    const normalized = Number.isFinite(untilMs)
      ? Math.max(0, Math.floor(untilMs))
      : 0;

    if (normalized === nextReturnEligibleAtMs) return;
    nextReturnEligibleAtMs = normalized;
    persistRuntimeState();
  }

  function captureOriginalEnv(): void {
    if (originalEnv) return;
    originalEnv = {
      openai_api_key: process.env.OPENAI_API_KEY,
      openai_org_id: process.env.OPENAI_ORG_ID,
      openai_project_id: process.env.OPENAI_PROJECT_ID,
      anthropic_api_key: process.env.ANTHROPIC_API_KEY,
    };
  }

  function restoreOriginalEnv(): void {
    if (!originalEnv) return;

    if (originalEnv.openai_api_key === undefined) delete process.env.OPENAI_API_KEY;
    else process.env.OPENAI_API_KEY = originalEnv.openai_api_key;

    if (originalEnv.openai_org_id === undefined) delete process.env.OPENAI_ORG_ID;
    else process.env.OPENAI_ORG_ID = originalEnv.openai_org_id;

    if (originalEnv.openai_project_id === undefined) delete process.env.OPENAI_PROJECT_ID;
    else process.env.OPENAI_PROJECT_ID = originalEnv.openai_project_id;

    if (originalEnv.anthropic_api_key === undefined) delete process.env.ANTHROPIC_API_KEY;
    else process.env.ANTHROPIC_API_KEY = originalEnv.anthropic_api_key;

    originalEnv = undefined;
  }

  function resolveApiKey(route: NormalizedRoute): string | undefined {
    if (route.api_key_env) {
      const v = process.env[route.api_key_env];
      if (v && v.trim()) return v.trim();
    }

    if (route.api_key_path) {
      try {
        const path = expandHome(route.api_key_path);
        if (existsSync(path)) {
          const raw = readFileSync(path, "utf-8").trim();
          if (raw) return raw;
        }
      } catch {
        // ignored
      }
    }

    if (route.api_key && route.api_key.trim()) return route.api_key.trim();

    return undefined;
  }

  function applyApiRouteCredentials(vendor: string, route: NormalizedRoute): boolean {
    const key = resolveApiKey(route);
    if (!key) return false;

    captureOriginalEnv();

    if (vendor === "openai") {
      process.env.OPENAI_API_KEY = key;

      if (route.openai_org_id_env) {
        const org = process.env[route.openai_org_id_env];
        if (org && org.trim()) process.env.OPENAI_ORG_ID = org.trim();
        else delete process.env.OPENAI_ORG_ID;
      } else {
        delete process.env.OPENAI_ORG_ID;
      }

      if (route.openai_project_id_env) {
        const project = process.env[route.openai_project_id_env];
        if (project && project.trim()) process.env.OPENAI_PROJECT_ID = project.trim();
        else delete process.env.OPENAI_PROJECT_ID;
      } else {
        delete process.env.OPENAI_PROJECT_ID;
      }

      return true;
    }

    if (vendor === "claude" || vendor === "anthropic") {
      process.env.ANTHROPIC_API_KEY = key;
      return true;
    }

    return false;
  }

  function getRouteCooldownUntil(vendor: string, index: number): number {
    const key = routeStateKey(vendor, index);
    if (!key) return 0;
    return routeCooldownUntil.get(key) ?? 0;
  }

  function setRouteCooldownUntil(vendor: string, index: number, untilMs: number): void {
    const key = routeStateKey(vendor, index);
    if (!key) return;

    const normalized = Number.isFinite(untilMs)
      ? Math.max(0, Math.floor(untilMs))
      : 0;
    const previous = routeCooldownUntil.get(key) ?? 0;

    if (normalized <= now()) {
      if (previous !== 0) {
        routeCooldownUntil.delete(key);
        persistRuntimeState();
      }
      return;
    }

    if (previous === normalized) return;

    routeCooldownUntil.set(key, normalized);
    persistRuntimeState();
  }

  function isRouteCoolingDown(vendor: string, index: number): boolean {
    const until = getRouteCooldownUntil(vendor, index);
    return Boolean(until && now() < until);
  }

  function routeDefaultCooldownMinutes(vendorCfg: NormalizedVendor, route: NormalizedRoute): number {
    if (route.cooldown_minutes !== undefined) return route.cooldown_minutes;
    return route.auth_type === "oauth"
      ? vendorCfg.oauth_cooldown_minutes
      : vendorCfg.api_key_cooldown_minutes;
  }

  function findRouteIndex(vendor: string, authType: AuthType, label: string): number | undefined {
    const v = getVendor(vendor);
    if (!v) return undefined;

    const want = label.trim().toLowerCase();
    const idx = v.routes.findIndex(
      (r) => r.auth_type === authType && r.label.trim().toLowerCase() === want,
    );
    return idx >= 0 ? idx : undefined;
  }

  function routeCanHandleModel(ctx: any, route: NormalizedRoute, modelId: string): boolean {
    return Boolean(ctx.modelRegistry.find(route.provider_id, modelId));
  }

  function routeHasUsableCredentials(vendor: string, route: NormalizedRoute): boolean {
    if (route.auth_type === "oauth") return true;
    return Boolean(resolveApiKey(route));
  }

  function routeEligible(ctx: any, vendor: string, index: number, modelId: string): boolean {
    const route = getRoute(vendor, index);
    if (!route) return false;
    if (isRouteCoolingDown(vendor, index)) return false;
    if (!routeCanHandleModel(ctx, route, modelId)) return false;
    if (!routeHasUsableCredentials(vendor, route)) return false;
    return true;
  }

  function routeEligibleRef(ctx: any, ref: ResolvedRouteRef, modelId: string): boolean {
    return routeEligible(ctx, ref.vendor, ref.index, modelId);
  }

  function buildEffectivePreferenceStack(
    currentVendor: string | undefined,
    currentModelId: string | undefined,
  ): EffectivePreferenceEntry[] {
    if (!cfg) return [];

    const effective: EffectivePreferenceEntry[] = [];
    for (let i = 0; i < cfg.preference_stack.length; i++) {
      const entry = cfg.preference_stack[i];
      const routeRef = resolveRouteById(entry.route_id);
      if (!routeRef) continue;

      if (
        cfg.failover.scope === "current_vendor" &&
        currentVendor &&
        routeRef.vendor !== currentVendor
      ) {
        continue;
      }

      const modelId = entry.model ?? currentModelId;
      if (!modelId) continue;

      effective.push({
        stack_index: i,
        route_ref: routeRef,
        model_id: modelId,
        model_source: entry.model ? "entry" : "current",
      });
    }

    return effective;
  }

  function findCurrentEffectiveStackIndex(
    effective: EffectivePreferenceEntry[],
    currentRouteId: string,
    currentModelId: string,
  ): number | undefined {
    const exact = effective.findIndex(
      (entry) => entry.route_ref.route.id === currentRouteId && entry.model_id === currentModelId,
    );
    if (exact >= 0) return exact;

    const routeOnly = effective.findIndex((entry) => entry.route_ref.route.id === currentRouteId);
    return routeOnly >= 0 ? routeOnly : undefined;
  }

  function clearRetryTimer(): void {
    if (retryTimer) {
      clearTimeout(retryTimer);
      retryTimer = undefined;
    }
  }

  function computeNextRecoveryEvent(): number | undefined {
    let next: number | undefined;

    for (const until of routeCooldownUntil.values()) {
      if (!until || until <= now()) continue;
      if (!next || until < next) next = until;
    }

    if (cfg?.failover.return_to_preferred.enabled && nextReturnEligibleAtMs > now()) {
      if (!next || nextReturnEligibleAtMs < next) next = nextReturnEligibleAtMs;
    }

    return next;
  }

  function extractCodexAccountId(token: string): string | undefined {
    try {
      const parts = token.split(".");
      if (parts.length !== 3) return undefined;

      const normalized = parts[1].replace(/-/g, "+").replace(/_/g, "/");
      const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, "=");

      const payload = JSON.parse(Buffer.from(padded, "base64").toString("utf-8"));
      const claim = payload?.["https://api.openai.com/auth"];
      const accountId = claim?.chatgpt_account_id;
      return accountId ? String(accountId) : undefined;
    } catch {
      return undefined;
    }
  }

  function resolveCodexProbeUrl(baseUrl: string): string {
    const raw = String(baseUrl ?? "").trim() || "https://chatgpt.com/backend-api";
    const normalized = raw.replace(/\/+$/, "");
    if (normalized.endsWith("/codex/responses")) return normalized;
    if (normalized.endsWith("/codex")) return `${normalized}/responses`;
    return `${normalized}/codex/responses`;
  }

  function trimProbeMessage(message: string): string {
    const oneLine = String(message ?? "").replace(/\s+/g, " ").trim();
    if (!oneLine) return "unknown probe error";
    if (oneLine.length <= 180) return oneLine;
    return `${oneLine.slice(0, 177)}...`;
  }

  function applyOpenAIRouteHeaders(route: NormalizedRoute, headers: Headers): void {
    if (route.openai_org_id_env) {
      const org = process.env[route.openai_org_id_env];
      if (org && org.trim()) headers.set("OpenAI-Organization", org.trim());
    }

    if (route.openai_project_id_env) {
      const project = process.env[route.openai_project_id_env];
      if (project && project.trim()) headers.set("OpenAI-Project", project.trim());
    }
  }

  async function parseProbeFailureResponse(response: Response): Promise<string> {
    const rawText = (await response.text()).trim();
    if (!rawText) return `HTTP ${response.status}`;

    try {
      const parsed = JSON.parse(rawText);
      const msg =
        parsed?.error?.message ??
        parsed?.error?.details ??
        parsed?.message ??
        parsed?.detail ??
        rawText;
      return trimProbeMessage(`HTTP ${response.status}: ${String(msg)}`);
    } catch {
      return trimProbeMessage(`HTTP ${response.status}: ${rawText}`);
    }
  }

  async function runRouteProbeRequest(
    model: any,
    route: NormalizedRoute,
    apiKey: string,
    signal: AbortSignal,
  ): Promise<Response> {
    const api = String(model?.api ?? "").trim();
    const baseUrl = String(model?.baseUrl ?? "").trim().replace(/\/+$/, "");

    if (api === "openai-codex-responses") {
      const headers = new Headers(model?.headers ?? {});
      headers.set("Authorization", `Bearer ${apiKey}`);
      headers.set("OpenAI-Beta", "responses=experimental");
      headers.set("originator", "pi");
      headers.set("User-Agent", "pi-subswitch-probe");
      headers.set("accept", "application/json");
      headers.set("content-type", "application/json");

      const accountId = extractCodexAccountId(apiKey);
      if (accountId) headers.set("chatgpt-account-id", accountId);

      const body = {
        model: model.id,
        store: false,
        stream: false,
        input: [{ role: "user", content: [{ type: "input_text", text: "health check" }] }],
        text: { verbosity: "low" },
      };

      return fetch(resolveCodexProbeUrl(baseUrl), {
        method: "POST",
        headers,
        body: JSON.stringify(body),
        signal,
      });
    }

    if (api === "openai-responses" || api === "openai-completions") {
      const headers = new Headers(model?.headers ?? {});
      headers.set("Authorization", `Bearer ${apiKey}`);
      headers.set("accept", "application/json");
      headers.set("content-type", "application/json");
      applyOpenAIRouteHeaders(route, headers);

      if (api === "openai-responses") {
        const body = {
          model: model.id,
          input: "health check",
          max_output_tokens: 1,
          store: false,
        };
        return fetch(`${baseUrl}/responses`, {
          method: "POST",
          headers,
          body: JSON.stringify(body),
          signal,
        });
      }

      const body = {
        model: model.id,
        messages: [{ role: "user", content: "health check" }],
        max_tokens: 1,
        temperature: 0,
      };
      return fetch(`${baseUrl}/chat/completions`, {
        method: "POST",
        headers,
        body: JSON.stringify(body),
        signal,
      });
    }

    if (api === "anthropic-messages") {
      const headers = new Headers(model?.headers ?? {});
      const isOauth = apiKey.includes("sk-ant-oat");

      headers.set("accept", "application/json");
      headers.set("content-type", "application/json");
      headers.set("anthropic-version", "2023-06-01");
      headers.set("anthropic-dangerous-direct-browser-access", "true");

      if (isOauth) {
        headers.set("Authorization", `Bearer ${apiKey}`);
        headers.set(
          "anthropic-beta",
          "claude-code-20250219,oauth-2025-04-20,fine-grained-tool-streaming-2025-05-14,interleaved-thinking-2025-05-14",
        );
        headers.set("user-agent", "claude-cli/2.1.2 (external, cli)");
        headers.set("x-app", "cli");
      } else {
        headers.set("x-api-key", apiKey);
        headers.set(
          "anthropic-beta",
          "fine-grained-tool-streaming-2025-05-14,interleaved-thinking-2025-05-14",
        );
      }

      const body: any = {
        model: model.id,
        max_tokens: 1,
        stream: false,
        messages: [{ role: "user", content: "health check" }],
      };

      if (isOauth) {
        body.system = [
          {
            type: "text",
            text: "You are Claude Code, Anthropic's official CLI for Claude.",
          },
        ];
      }

      const url = baseUrl.endsWith("/v1") ? `${baseUrl}/messages` : `${baseUrl}/v1/messages`;
      return fetch(url, {
        method: "POST",
        headers,
        body: JSON.stringify(body),
        signal,
      });
    }

    throw new Error(`unsupported probe api '${api || "unknown"}'`);
  }

  async function probeRouteModel(
    ctx: any,
    ref: ResolvedRouteRef,
    modelId: string,
  ): Promise<RouteProbeResult> {
    const route = ref.route;
    const model = ctx.modelRegistry.find(route.provider_id, modelId);
    if (!model) {
      return {
        ok: false,
        message: `model unavailable for probe (${route.provider_id}/${modelId})`,
      };
    }

    let apiKey: string | undefined;
    if (route.auth_type === "api_key") {
      apiKey = resolveApiKey(route);
    } else {
      try {
        const key = await ctx.modelRegistry.getApiKey(model);
        apiKey = key ? String(key).trim() : undefined;
      } catch {
        apiKey = undefined;
      }
    }

    if (!apiKey) {
      return { ok: false, message: "missing credentials for probe" };
    }

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), RETURN_PROBE_TIMEOUT_MS);

    try {
      const response = await runRouteProbeRequest(model, route, apiKey, controller.signal);
      if (response.ok) return { ok: true };

      const message = await parseProbeFailureResponse(response);
      return {
        ok: false,
        message,
        retry_after_ms: parseRetryAfterMs(message),
      };
    } catch (error) {
      const message = trimProbeMessage(
        error instanceof Error ? error.message : String(error),
      );
      return {
        ok: false,
        message,
        retry_after_ms: parseRetryAfterMs(message),
      };
    } finally {
      clearTimeout(timeout);
    }
  }

  function probeFailureCooldownMs(
    vendorCfg: NormalizedVendor,
    route: NormalizedRoute,
    probe: RouteProbeResult,
  ): number {
    if (probe.retry_after_ms !== undefined && probe.retry_after_ms > 0) {
      return Math.max(
        RETURN_PROBE_MIN_COOLDOWN_MS,
        Math.min(probe.retry_after_ms + 5_000, RETURN_PROBE_MAX_COOLDOWN_MS),
      );
    }

    const configuredMs = routeDefaultCooldownMinutes(vendorCfg, route) * 60_000;
    return Math.max(
      RETURN_PROBE_MIN_COOLDOWN_MS,
      Math.min(configuredMs, RETURN_PROBE_MAX_COOLDOWN_MS),
    );
  }

  async function maybePromotePreferredRoute(ctx: any, reason: string): Promise<void> {
    if (!cfg?.enabled) return;
    if (!cfg.failover.return_to_preferred.enabled) return;
    if (!ctx.model?.id || !ctx.model?.provider) return;
    if (nextReturnEligibleAtMs > now()) return;

    const resolved = resolveVendorRouteForProvider(ctx.model.provider);
    if (!resolved) return;

    const currentRoute = getRoute(resolved.vendor, resolved.index);
    if (!currentRoute) return;

    const currentModelId = ctx.model.id;
    const effective = buildEffectivePreferenceStack(resolved.vendor, currentModelId);
    if (effective.length === 0) return;

    const currentIdx = findCurrentEffectiveStackIndex(effective, currentRoute.id, currentModelId);
    const bestIdx = effective.findIndex((entry) => routeEligibleRef(ctx, entry.route_ref, entry.model_id));
    if (bestIdx < 0) return;

    if (currentIdx !== undefined && bestIdx >= currentIdx) return;

    const target = effective[bestIdx];
    const targetVendorCfg = getVendor(target.route_ref.vendor);
    if (!targetVendorCfg) return;

    if (ctx.hasUI) {
      ctx.ui.notify(
        `[${EXT}] Checking preferred route health: ${routeDisplay(target.route_ref.vendor, target.route_ref.route)} (${target.model_id})`,
        "info",
      );
    }

    const probe = await probeRouteModel(ctx, target.route_ref, target.model_id);
    if (!probe.ok) {
      const cooldownMs = probeFailureCooldownMs(
        targetVendorCfg,
        target.route_ref.route,
        probe,
      );
      const cooldownUntil = now() + cooldownMs;
      setRouteCooldownUntil(target.route_ref.vendor, target.route_ref.index, cooldownUntil);

      if (ctx.hasUI) {
        const mins = Math.max(0, Math.ceil(cooldownMs / 60000));
        const reasonText = probe.message ? ` Probe error: ${probe.message}` : "";
        ctx.ui.notify(
          `[${EXT}] Preferred route still unavailable. Staying on ${routeDisplay(resolved.vendor, currentRoute)} (${currentModelId}). Retry in ~${mins}m.${reasonText}`,
          "warning",
        );
      }

      scheduleRetryTimer(ctx);
      updateStatus(ctx);
      return;
    }

    if (ctx.hasUI) {
      ctx.ui.notify(
        `[${EXT}] Preferred route is healthy again; switching to ${routeDisplay(target.route_ref.vendor, target.route_ref.route)} (${target.model_id})`,
        "info",
      );
    }

    const switched = await switchToRoute(
      ctx,
      target.route_ref.vendor,
      target.route_ref.index,
      target.model_id,
      reason,
      true,
    );

    if (!switched && ctx.hasUI) {
      ctx.ui.notify(
        `[${EXT}] Preferred route probe passed, but model switch failed. Staying on ${routeDisplay(resolved.vendor, currentRoute)} (${currentModelId}).`,
        "warning",
      );
    }
  }

  function scheduleRetryTimer(ctx: any): void {
    clearRetryTimer();

    const next = computeNextRecoveryEvent();
    if (!next) return;

    const delay = Math.max(1000, next - now());
    retryTimer = setTimeout(async () => {
      retryTimer = undefined;

      if (!lastCtx) {
        scheduleRetryTimer(ctx);
        return;
      }

      if (typeof lastCtx.isIdle === "function" && !lastCtx.isIdle()) {
        scheduleRetryTimer(lastCtx);
        return;
      }

      try {
        await maybePromotePreferredRoute(lastCtx, "cooldown expired");
      } finally {
        scheduleRetryTimer(lastCtx);
      }
    }, delay);
  }

  function registerOpenAICodexAliasProvider(providerId: string): void {
    if (!providerId || registeredAliases.has(providerId)) return;
    if (providerId === "openai-codex") return;

    // Avoid accidentally overriding common non-Codex providers.
    if (["openai", "anthropic", "github-copilot", "google", "google-gemini-cli"].includes(providerId)) {
      return;
    }

    const models = cloneProviderModels("openai-codex");
    const baseUrl = providerBaseUrl("openai-codex");
    if (models.length === 0 || !baseUrl) return;

    const label = providerId;

    pi.registerProvider(providerId, {
      baseUrl,
      models,
      oauth: {
        name: `ChatGPT Plus/Pro (Codex Subscription) (${label})`,
        async login(callbacks: any) {
          return loginOpenAICodex({
            onAuth: callbacks.onAuth,
            onPrompt: callbacks.onPrompt,
            onProgress: callbacks.onProgress,
            onManualCodeInput: callbacks.onManualCodeInput,
            originator: providerId,
          });
        },
        async refreshToken(credentials: any) {
          return refreshOpenAICodexToken(String(credentials.refresh));
        },
        getApiKey(credentials: any) {
          return String(credentials.access);
        },
      },
    });

    registeredAliases.add(providerId);
  }

  function registerAnthropicOAuthAliasProvider(providerId: string): void {
    if (!providerId || registeredAliases.has(providerId)) return;
    if (providerId === "anthropic") return;

    // Avoid accidentally overriding common non-Anthropic providers.
    if (["openai", "openai-codex", "github-copilot", "google", "google-gemini-cli"].includes(providerId)) {
      return;
    }

    const models = cloneProviderModels("anthropic");
    const baseUrl = providerBaseUrl("anthropic");
    if (models.length === 0 || !baseUrl) return;

    const label = providerId;

    pi.registerProvider(providerId, {
      baseUrl,
      models,
      oauth: {
        name: `Anthropic (Claude Pro/Max) (${label})`,
        async login(callbacks: any) {
          return loginAnthropic(
            (url) => callbacks.onAuth({ url }),
            () => callbacks.onPrompt({ message: "Paste the authorization code:" }),
          );
        },
        async refreshToken(credentials: any) {
          return refreshAnthropicToken(String(credentials.refresh));
        },
        getApiKey(credentials: any) {
          return String(credentials.access);
        },
      },
    });

    registeredAliases.add(providerId);
  }

  function registerOpenAIApiAliasProvider(providerId: string): void {
    if (!providerId || registeredAliases.has(providerId)) return;
    if (providerId === "openai") return;

    const models = cloneProviderModels("openai");
    const baseUrl = providerBaseUrl("openai");
    if (models.length === 0 || !baseUrl) return;

    pi.registerProvider(providerId, {
      baseUrl,
      apiKey: "OPENAI_API_KEY",
      api: models[0]?.api,
      models,
    });

    registeredAliases.add(providerId);
  }

  function registerAnthropicApiAliasProvider(providerId: string): void {
    if (!providerId || registeredAliases.has(providerId)) return;
    if (providerId === "anthropic") return;

    const models = cloneProviderModels("anthropic");
    const baseUrl = providerBaseUrl("anthropic");
    if (models.length === 0 || !baseUrl) return;

    pi.registerProvider(providerId, {
      baseUrl,
      apiKey: "ANTHROPIC_API_KEY",
      api: models[0]?.api,
      models,
    });

    registeredAliases.add(providerId);
  }

  function registerAliasesFromConfig(nextCfg: NormalizedConfig): void {
    for (const v of nextCfg.vendors) {
      for (const route of v.routes) {
        if (route.auth_type === "oauth") {
          if (v.vendor === "openai") registerOpenAICodexAliasProvider(route.provider_id);
          if (v.vendor === "claude" || v.vendor === "anthropic")
            registerAnthropicOAuthAliasProvider(route.provider_id);
        } else {
          if (v.vendor === "openai" && route.provider_id !== "openai") {
            registerOpenAIApiAliasProvider(route.provider_id);
          }
          if ((v.vendor === "claude" || v.vendor === "anthropic") && route.provider_id !== "anthropic") {
            registerAnthropicApiAliasProvider(route.provider_id);
          }
        }
      }
    }
  }

  function resolveVendorRouteForProvider(providerId: string): { vendor: string; index: number } | undefined {
    if (!cfg) return undefined;

    // Prefer known active index first.
    for (const [vendor, idx] of activeRouteIndexByVendor.entries()) {
      const route = getRoute(vendor, idx);
      if (route && route.provider_id === providerId) {
        return { vendor, index: idx };
      }
    }

    // Fallback to first route match.
    for (const v of cfg.vendors) {
      for (let i = 0; i < v.routes.length; i++) {
        if (v.routes[i].provider_id === providerId) {
          return { vendor: v.vendor, index: i };
        }
      }
    }

    return undefined;
  }

  function rememberActiveFromCtx(ctx: any): void {
    if (!cfg) return;

    const provider = ctx.model?.provider;
    if (!provider) return;

    const resolved = resolveVendorRouteForProvider(provider);
    if (!resolved) return;

    activeVendor = resolved.vendor;
    activeRouteIndexByVendor.set(resolved.vendor, resolved.index);
  }

  function nearestPreferredCooldownHint(
    currentVendor: string,
    currentRouteId: string,
    currentModelId: string,
  ): string | undefined {
    const effective = buildEffectivePreferenceStack(currentVendor, currentModelId);
    if (effective.length === 0) return undefined;

    const currentIdx = findCurrentEffectiveStackIndex(effective, currentRouteId, currentModelId);
    if (currentIdx === undefined || currentIdx <= 0) return undefined;

    let nearestUntil: number | undefined;
    for (let i = 0; i < currentIdx; i++) {
      const candidate = effective[i];
      const until = getRouteCooldownUntil(candidate.route_ref.vendor, candidate.route_ref.index);
      if (!until || until <= now()) continue;
      if (!nearestUntil || until < nearestUntil) nearestUntil = until;
    }

    if (!nearestUntil) return undefined;

    const mins = Math.max(0, Math.ceil((nearestUntil - now()) / 60000));
    return `preferred retry ~${mins}m`;
  }

  function updateStatus(ctx: any): void {
    if (!ctx.hasUI) return;

    if (!cfg?.enabled) {
      ctx.ui.setStatus(EXT, undefined);
      return;
    }

    const provider = ctx.model?.provider;
    const modelId = ctx.model?.id;
    if (!provider || !modelId) {
      ctx.ui.setStatus(EXT, undefined);
      return;
    }

    const resolved = resolveVendorRouteForProvider(provider);
    if (!resolved) {
      ctx.ui.setStatus(EXT, ctx.ui.theme.fg("muted", `${EXT}:`) + " " + provider + "/" + modelId);
      return;
    }

    const route = getRoute(resolved.vendor, resolved.index);
    if (!route) {
      ctx.ui.setStatus(EXT, ctx.ui.theme.fg("muted", `${EXT}:`) + " " + provider + "/" + modelId);
      return;
    }

    let state = "ready";
    if (isRouteCoolingDown(resolved.vendor, resolved.index)) {
      const mins = Math.max(
        0,
        Math.ceil((getRouteCooldownUntil(resolved.vendor, resolved.index) - now()) / 60000),
      );
      state = `cooldown~${mins}m`;
    } else if (!routeCanHandleModel(ctx, route, modelId)) {
      state = "model_unavailable";
    } else if (!routeHasUsableCredentials(resolved.vendor, route)) {
      state = "missing_credentials";
    }

    const stateDisplay = state === "ready" ? ctx.ui.theme.fg("success", state) : state;

    let msg = ctx.ui.theme.fg("muted", `${EXT}:`);
    msg += " " + ctx.ui.theme.fg("accent", route.auth_type === "oauth" ? "sub" : "api");
    msg += " " + ctx.ui.theme.fg("dim", `${resolved.vendor}/${route.label}`);
    msg += " " + ctx.ui.theme.fg("dim", modelId);
    msg += " " + stateDisplay;

    const hint = nearestPreferredCooldownHint(resolved.vendor, route.id, modelId);
    if (hint) msg += " " + ctx.ui.theme.fg("dim", `(${hint})`);

    ctx.ui.setStatus(EXT, msg);
  }

  function buildStatusLines(ctx: any, detailed = false, colorizeReady = false): string[] {
    if (!cfg) return ["(no config loaded)"];

    const lines: string[] = [];

    const displayState = (state: string): string => {
      if (state === "ready" && colorizeReady && ctx.hasUI) {
        return ctx.ui.theme.fg("success", state);
      }
      return state;
    };

    const currentProvider = ctx.model?.provider;
    const currentModel = ctx.model?.id;
    const currentResolved = currentProvider ? resolveVendorRouteForProvider(currentProvider) : undefined;
    const currentRoute = currentResolved
      ? getRoute(currentResolved.vendor, currentResolved.index)
      : undefined;

    if (detailed) {
      lines.push(`[${EXT}] enabled=${cfg.enabled} default_vendor=${cfg.default_vendor}`);
      lines.push(
        `failover scope=${cfg.failover.scope} return_to_preferred=${cfg.failover.return_to_preferred.enabled} stable=${cfg.failover.return_to_preferred.min_stable_minutes}m triggers(rate_limit=${cfg.failover.triggers.rate_limit},quota=${cfg.failover.triggers.quota_exhausted},auth=${cfg.failover.triggers.auth_error})`,
      );

      if (nextReturnEligibleAtMs > now()) {
        const mins = Math.max(0, Math.ceil((nextReturnEligibleAtMs - now()) / 60000));
        lines.push(`return_holdoff~${mins}m`);
      }

      if (currentProvider && currentModel) {
        lines.push(`current_model=${currentProvider}/${currentModel}`);
      }
    }

    lines.push("preference_stack:");
    for (let i = 0; i < cfg.preference_stack.length; i++) {
      const entry = cfg.preference_stack[i];
      const ref = resolveRouteById(entry.route_id);
      if (!ref) {
        lines.push(`  ${i + 1}. [missing route_id=${entry.route_id}]`);
        continue;
      }

      const modelId = entry.model ?? currentModel;

      const isActive =
        currentRoute !== undefined &&
        currentRoute.id === ref.route.id &&
        (entry.model === undefined || entry.model === currentModel);

      let state = "ready";
      if (!modelId) {
        state = "waiting_for_current_model";
      } else if (isRouteCoolingDown(ref.vendor, ref.index)) {
        const mins = Math.max(
          0,
          Math.ceil((getRouteCooldownUntil(ref.vendor, ref.index) - now()) / 60000),
        );
        state = `cooldown~${mins}m`;
      } else if (!routeCanHandleModel(ctx, ref.route, modelId)) {
        state = "model_unavailable";
      } else if (!routeHasUsableCredentials(ref.vendor, ref.route)) {
        state = "missing_credentials";
      }

      const activeMark = isActive ? "*" : " ";
      const stateDisplay = displayState(state);
      if (detailed) {
        const modelOverridePart = entry.model ? `, model_override=${entry.model}` : "";
        lines.push(
          `  ${activeMark} ${i + 1}. ${routeDisplay(ref.vendor, ref.route)} (id=${ref.route.id}, provider=${ref.route.provider_id}${modelOverridePart}, ${stateDisplay})`,
        );
      } else {
        lines.push(
          `  ${activeMark} ${i + 1}. ${routeDisplay(ref.vendor, ref.route)} (${stateDisplay})`,
        );
      }
    }

    if (detailed) {
      for (const v of cfg.vendors) {
        lines.push(`vendor ${v.vendor}:`);
        for (let i = 0; i < v.routes.length; i++) {
          const route = v.routes[i];
          const active = activeRouteIndexByVendor.get(v.vendor) === i ? "*" : " ";
          const cooling = isRouteCoolingDown(v.vendor, i)
            ? `cooldown~${Math.max(0, Math.ceil((getRouteCooldownUntil(v.vendor, i) - now()) / 60000))}m`
            : "ready";
          lines.push(
            `  ${active} ${i + 1}. ${route.auth_type} ${decode(route.label)} (id=${route.id}, provider=${route.provider_id}, ${displayState(cooling)})`,
          );
        }
      }
    }

    return lines;
  }

  function notifyStatus(ctx: any, detailed = false): void {
    if (!ctx.hasUI) return;
    ctx.ui.notify(buildStatusLines(ctx, detailed, true).join("\n"), "info");
  }

  function configuredOauthProviders(): string[] {
    if (!cfg) return [];
    const providers: string[] = [];
    for (const v of cfg.vendors) {
      for (const route of v.routes) {
        if (route.auth_type === "oauth") providers.push(route.provider_id);
      }
    }
    return Array.from(new Set(providers));
  }

  function findAnyModelForProvider(ctx: any, providerId: string): any | undefined {
    const currentModelId = ctx.model?.id;
    if (currentModelId) {
      const m = ctx.modelRegistry.find(providerId, currentModelId);
      if (m) return m;
    }

    const available = (ctx.modelRegistry.getAvailable?.() ?? []) as any[];
    return available.find((m) => m?.provider === providerId);
  }

  async function isOauthProviderAuthenticated(ctx: any, providerId: string): Promise<boolean> {
    if (!ctx?.modelRegistry?.getApiKey) return false;

    const model = findAnyModelForProvider(ctx, providerId);
    if (!model) return false;

    try {
      const apiKey = await ctx.modelRegistry.getApiKey(model);
      return Boolean(apiKey && String(apiKey).trim());
    } catch {
      return false;
    }
  }

  async function missingOauthProviders(
    ctx: any,
    providers: string[],
  ): Promise<string[]> {
    const missing: string[] = [];
    for (const provider of providers) {
      const ok = await isOauthProviderAuthenticated(ctx, provider);
      if (!ok) missing.push(provider);
    }
    return missing;
  }

  async function refreshOauthReminderWidget(
    ctx: any,
    providers?: string[],
  ): Promise<string[]> {
    const candidates = providers ? Array.from(new Set(providers)) : configuredOauthProviders();
    const missing = await missingOauthProviders(ctx, candidates);
    pendingOauthReminderProviders = missing;

    if (ctx.hasUI) {
      if (missing.length === 0) {
        ctx.ui.setWidget(LOGIN_WIDGET_KEY, undefined);
      } else {
        const lines = [
          "⚠ subswitch setup incomplete: OAuth login required",
          "Run /login and authenticate providers:",
          ...missing.map((p) => `  - ${p}`),
          "Use /subswitch login-status to re-check.",
        ];
        ctx.ui.setWidget(LOGIN_WIDGET_KEY, lines, { placement: "belowEditor" });
      }
    }

    return missing;
  }

  async function promptOauthLogin(
    ctx: any,
    providers?: string[],
  ): Promise<void> {
    const missing = await refreshOauthReminderWidget(ctx, providers);
    if (missing.length === 0) {
      if (ctx.hasUI) {
        ctx.ui.notify(`[${EXT}] OAuth providers already authenticated`, "info");
      }
      return;
    }

    if (!ctx.hasUI) return;

    const choice = await ctx.ui.select("OAuth login required", [
      "Start /login now",
      "Remind me later",
    ]);

    if (choice === "Start /login now") {
      ctx.ui.setEditorText("/login");
      ctx.ui.notify(
        `[${EXT}] Prefilled /login. After each login, run /subswitch login-status.`,
        "warning",
      );
    } else {
      ctx.ui.notify(
        `[${EXT}] Reminder saved. Run /subswitch login to resume OAuth login flow.`,
        "info",
      );
    }
  }

  async function switchToRoute(
    ctx: any,
    vendor: string,
    routeIndex: number,
    modelId: string,
    reason: string,
    notify = true,
  ): Promise<boolean> {
    if (!cfg?.enabled) return false;

    const vendorCfg = getVendor(vendor);
    const route = getRoute(vendor, routeIndex);
    if (!vendorCfg || !route) return false;

    if (!routeCanHandleModel(ctx, route, modelId)) {
      if (notify && ctx.hasUI) {
        ctx.ui.notify(
          `[${EXT}] Route cannot serve model ${modelId}: ${routeDisplay(vendor, route)}`,
          "warning",
        );
      }
      return false;
    }

    if (route.auth_type === "api_key") {
      const ok = applyApiRouteCredentials(vendor, route);
      if (!ok) {
        if (notify && ctx.hasUI) {
          ctx.ui.notify(
            `[${EXT}] Missing API key material for ${routeDisplay(vendor, route)} (check api_key_env/api_key_path/api_key)`,
            "warning",
          );
        }
        return false;
      }
    }

    const model = ctx.modelRegistry.find(route.provider_id, modelId);
    if (!model) {
      if (notify && ctx.hasUI) {
        ctx.ui.notify(
          `[${EXT}] No model ${route.provider_id}/${modelId} (${reason})`,
          "warning",
        );
      }
      return false;
    }

    pendingExtensionSwitch = { provider: route.provider_id, modelId };

    let ok = false;
    try {
      ok = await pi.setModel(model);
    } finally {
      if (!ok) pendingExtensionSwitch = undefined;
    }

    if (!ok) {
      if (notify && ctx.hasUI) {
        ctx.ui.notify(
          `[${EXT}] Missing credentials for ${route.provider_id}/${modelId} (${reason})`,
          "warning",
        );
      }
      return false;
    }

    activeVendor = vendor;
    activeRouteIndexByVendor.set(vendor, routeIndex);
    managedModelId = modelId;

    if (notify && ctx.hasUI) {
      ctx.ui.notify(
        `[${EXT}] Switched to ${routeDisplay(vendor, route)} (${route.provider_id}/${modelId})`,
        "info",
      );
    }

    updateStatus(ctx);
    scheduleRetryTimer(ctx);
    return true;
  }

  async function useRouteBySelector(
    ctx: any,
    vendor: string,
    authType: AuthType,
    label: string,
    modelId?: string,
    reason = "manual",
  ): Promise<boolean> {
    ensureCfg(ctx);

    const v = getVendor(vendor);
    if (!v) {
      if (ctx.hasUI) ctx.ui.notify(`[${EXT}] Unknown vendor '${vendor}'`, "warning");
      return false;
    }

    const idx = findRouteIndex(vendor, authType, label);
    if (idx === undefined) {
      if (ctx.hasUI) {
        ctx.ui.notify(
          `[${EXT}] No route '${label}' with auth_type='${authType}' for vendor '${vendor}'`,
          "warning",
        );
      }
      return false;
    }

    const targetModelId = modelId ?? ctx.model?.id;
    if (!targetModelId) {
      if (ctx.hasUI) {
        ctx.ui.notify(`[${EXT}] No current model selected; specify model id explicitly`, "warning");
      }
      return false;
    }

    return switchToRoute(ctx, vendor, idx, targetModelId, reason, true);
  }

  async function useFirstRouteForAuthType(
    ctx: any,
    vendor: string,
    authType: AuthType,
    label: string | undefined,
    modelId?: string,
    reason = "manual",
  ): Promise<boolean> {
    ensureCfg(ctx);

    const v = getVendor(vendor);
    if (!v) {
      if (ctx.hasUI) ctx.ui.notify(`[${EXT}] Unknown vendor '${vendor}'`, "warning");
      return false;
    }

    const targetModelId = modelId ?? ctx.model?.id;
    if (!targetModelId) {
      if (ctx.hasUI) {
        ctx.ui.notify(`[${EXT}] No current model selected; specify model id explicitly`, "warning");
      }
      return false;
    }

    let idx: number | undefined;

    if (label) {
      idx = findRouteIndex(vendor, authType, label);
      if (idx === undefined) {
        if (ctx.hasUI) {
          ctx.ui.notify(
            `[${EXT}] No ${authType} route '${label}' for vendor '${vendor}'`,
            "warning",
          );
        }
        return false;
      }
    } else {
      for (let i = 0; i < v.routes.length; i++) {
        const route = v.routes[i];
        if (route.auth_type !== authType) continue;
        if (!routeEligible(ctx, vendor, i, targetModelId)) continue;
        idx = i;
        break;
      }

      if (idx === undefined) {
        if (ctx.hasUI) {
          ctx.ui.notify(
            `[${EXT}] No eligible ${authType} route for vendor '${vendor}' and model '${targetModelId}'`,
            "warning",
          );
        }
        return false;
      }
    }

    return switchToRoute(ctx, vendor, idx, targetModelId, reason, true);
  }

  function routeOrderMoveToFront(vendor: string, authType: AuthType, label: string): boolean {
    const v = getVendor(vendor);
    if (!v || !cfg) return false;

    const idx = findRouteIndex(vendor, authType, label);
    if (idx === undefined) return false;

    const [picked] = v.routes.splice(idx, 1);
    v.routes.unshift(picked);

    // Reconcile active index if we touched this vendor.
    const current = activeRouteIndexByVendor.get(vendor);
    if (current !== undefined) {
      if (current === idx) {
        activeRouteIndexByVendor.set(vendor, 0);
      } else if (current < idx) {
        activeRouteIndexByVendor.set(vendor, current + 1);
      }
    }

    // Keep preference stack aligned with explicit route preference operations.
    const matching = cfg.preference_stack.filter((entry) => entry.route_id === picked.id);
    const rest = cfg.preference_stack.filter((entry) => entry.route_id !== picked.id);
    cfg.preference_stack = matching.length > 0 ? [...matching, ...rest] : [{ route_id: picked.id }, ...rest];

    return true;
  }

  function renameRoute(vendor: string, authType: AuthType, oldLabel: string, newLabel: string): boolean {
    const idx = findRouteIndex(vendor, authType, oldLabel);
    if (idx === undefined) return false;
    const route = getRoute(vendor, idx);
    if (!route) return false;
    route.label = newLabel.trim();
    return true;
  }

  function saveCurrentConfig(ctx: any): string {
    const path = preferredWritableConfigPath(ctx.cwd);
    if (!cfg) return path;

    writeJson(path, configToJson(cfg));
    statePath = statePathForConfigPath(ctx.cwd, path);
    pruneRuntimeState();
    persistRuntimeState();
    return path;
  }

  function vendorForCommand(ctx: any, candidate: string | undefined): string {
    if (candidate && candidate.trim()) return candidate.trim().toLowerCase();

    const provider = ctx.model?.provider;
    if (provider) {
      const resolved = resolveVendorRouteForProvider(provider);
      if (resolved) return resolved.vendor;
    }

    return cfg?.default_vendor ?? "openai";
  }

  async function showModelCompatibility(ctx: any, vendor: string): Promise<void> {
    ensureCfg(ctx);

    const v = getVendor(vendor);
    if (!v) {
      if (ctx.hasUI) ctx.ui.notify(`[${EXT}] Unknown vendor '${vendor}'`, "warning");
      return;
    }

    const available = ctx.modelRegistry.getAvailable() as any[];
    const byProvider = new Map<string, Set<string>>();

    for (const m of available) {
      const p = String(m.provider ?? "");
      const id = String(m.id ?? "");
      if (!p || !id) continue;
      if (!byProvider.has(p)) byProvider.set(p, new Set<string>());
      byProvider.get(p)?.add(id);
    }

    let intersection: Set<string> | undefined;
    for (const route of v.routes) {
      const ids = byProvider.get(route.provider_id) ?? new Set<string>();
      if (!intersection) {
        intersection = new Set(ids);
      } else {
        for (const id of Array.from(intersection)) {
          if (!ids.has(id)) intersection.delete(id);
        }
      }
    }

    const models = Array.from(intersection ?? []).sort();

    if (ctx.hasUI) {
      ctx.ui.notify(
        `[${EXT}] Compatible models for vendor '${vendor}' across ${v.routes.length} routes: ${
          models.length > 0 ? models.join(", ") : "(none)"
        }`,
        models.length > 0 ? "info" : "warning",
      );
    }
  }

  async function reorderVendorInteractive(ctx: any, vendorArg?: string): Promise<void> {
    ensureCfg(ctx);
    if (!ctx.hasUI || !cfg) {
      return;
    }

    const filterVendor = vendorArg ? vendorForCommand(ctx, vendorArg) : undefined;

    const indexed = cfg.preference_stack
      .map((entry, index) => ({ index, entry, ref: resolveRouteById(entry.route_id) }))
      .filter((x) => Boolean(x.ref))
      .filter((x) => !filterVendor || x.ref!.vendor === filterVendor);

    if (indexed.length < 2) {
      const scope = filterVendor ? `for vendor '${filterVendor}'` : "";
      ctx.ui.notify(`[${EXT}] Need at least 2 stack entries ${scope} to reorder`, "warning");
      return;
    }

    const labels = indexed.map((x, i) => {
      const ref = x.ref!;
      const model = x.entry.model ?? "current";
      return `${i + 1}. ${routeDisplay(ref.vendor, ref.route)} model=${model}`;
    });

    const fromChoice = await ctx.ui.select("Move which preference stack entry?", labels);
    if (!fromChoice) return;

    const fromLocal = labels.indexOf(fromChoice);
    if (fromLocal < 0) return;

    const toChoice = await ctx.ui.select("Move to which position?", labels);
    if (!toChoice) return;

    const toLocal = labels.indexOf(toChoice);
    if (toLocal < 0 || toLocal === fromLocal) return;

    const fromGlobal = indexed[fromLocal].index;
    const toGlobal = indexed[toLocal].index;

    const [picked] = cfg.preference_stack.splice(fromGlobal, 1);
    cfg.preference_stack.splice(toGlobal, 0, picked);

    const savePath = saveCurrentConfig(ctx);
    ctx.ui.notify(
      `[${EXT}] Reordered preference stack${filterVendor ? ` for '${filterVendor}'` : ""}. Saved to ${savePath}`,
      "info",
    );

    reloadCfg(ctx);
    updateStatus(ctx);
  }

  async function editConfigInteractive(ctx: any): Promise<void> {
    ensureCfg(ctx);

    if (!ctx.hasUI) {
      return;
    }

    const path = preferredWritableConfigPath(ctx.cwd);

    const currentJson = existsSync(path)
      ? readFileSync(path, "utf-8")
      : JSON.stringify(configToJson(cfg!), null, 2) + "\n";

    const edited = await ctx.ui.editor(`Edit ${path}`, currentJson);
    if (edited === undefined) return;

    let parsed: Config;
    try {
      parsed = JSON.parse(edited) as Config;
    } catch (e) {
      ctx.ui.notify(`[${EXT}] Invalid JSON: ${String(e)}`, "error");
      return;
    }

    const normalized = normalizeConfig(parsed);
    if (normalized.vendors.length === 0) {
      ctx.ui.notify(`[${EXT}] Config must define at least one vendor with routes`, "error");
      return;
    }

    writeJson(path, configToJson(normalized));
    cfg = normalized;
    registerAliasesFromConfig(cfg);

    ctx.ui.notify(`[${EXT}] Saved config to ${path}`, "info");
    updateStatus(ctx);
  }

  function generateOauthProviderId(vendor: string, label: string): string {
    const slug = slugify(label);
    if (vendor === "openai") {
      if (slug === "personal") return "openai-codex";
      return `openai-codex-${slug || "account"}`;
    }
    if (vendor === "claude" || vendor === "anthropic") {
      if (slug === "personal") return "anthropic";
      return `anthropic-${slug || "account"}`;
    }
    return `${vendor}-${slug || "oauth"}`;
  }

  function defaultApiEnvVar(vendor: string, label: string): string {
    const suffix = slugify(label).toUpperCase().replace(/-/g, "_") || "DEFAULT";
    if (vendor === "openai") return `OPENAI_API_KEY_${suffix}`;
    if (vendor === "claude" || vendor === "anthropic") return `ANTHROPIC_API_KEY_${suffix}`;
    return `${vendor.toUpperCase()}_API_KEY_${suffix}`;
  }

  async function setupWizard(ctx: any): Promise<void> {
    if (!ctx.hasUI) {
      return;
    }

    ctx.ui.notify(`[${EXT}] Starting setup wizard…`, "info");
    ctx.ui.notify(
      `[${EXT}] Changes are applied only when you finish setup. Cancel keeps current config.`,
      "info",
    );

    type WizardNav = "ok" | "back" | "cancel";

    async function inputWithBack(
      title: string,
      currentValue: string,
      options?: { allowEmpty?: boolean },
    ): Promise<{ nav: WizardNav; value?: string }> {
      const shownValue = String(currentValue ?? "");
      const currentDisplay = shownValue.trim() ? shownValue : "(empty)";
      const raw = await ctx.ui.input(
        `${title}\nCurrent: ${currentDisplay}\nPress Enter to keep current value.\nType /back to go to previous screen`,
        shownValue,
      );
      if (raw === undefined) return { nav: "cancel" };

      const trimmed = raw.trim();
      if (trimmed.toLowerCase() === "/back") return { nav: "back" };

      if (!options?.allowEmpty && trimmed === "") {
        return { nav: "ok", value: shownValue };
      }

      return { nav: "ok", value: raw };
    }

    async function collectVendor(
      vendor: "openai" | "claude",
      existing?: VendorConfig,
    ): Promise<{ nav: WizardNav; config?: VendorConfig }> {
      const vendorTitle = titleCase(vendor);
      const existingRoutes = Array.isArray(existing?.routes) ? existing.routes : [];

      const defaultOauthLabels =
        existingRoutes
          .filter((r) => r.auth_type === "oauth")
          .map((r) => String(r.label ?? "").trim())
          .filter(Boolean)
          .join(", ") || (vendor === "openai" ? "work, personal" : "personal");

      const defaultApiLabels =
        existingRoutes
          .filter((r) => r.auth_type === "api_key")
          .map((r) => String(r.label ?? "").trim())
          .filter(Boolean)
          .join(", ") || "work";

      const existingApiEnvByLabel = new Map<string, string>();
      const existingRouteIdByKey = new Map<string, string>();
      for (const route of existingRoutes) {
        const authType = route.auth_type === "api_key" ? "api_key" : "oauth";
        const label = String(route.label ?? "").trim();
        if (!label) continue;

        if (route.id && String(route.id).trim()) {
          existingRouteIdByKey.set(`${authType}::${label.toLowerCase()}`, String(route.id).trim());
        }

        if (route.auth_type !== "api_key") continue;
        if (route.api_key_env && String(route.api_key_env).trim()) {
          existingApiEnvByLabel.set(label, String(route.api_key_env).trim());
        }
      }

      let oauthRaw = defaultOauthLabels;
      let apiRaw = defaultApiLabels;

      while (true) {
        const oauthRes = await inputWithBack(
          `${vendorTitle} OAuth account labels (comma-separated, e.g. work, personal)`,
          oauthRaw,
        );
        if (oauthRes.nav === "cancel") return { nav: "cancel" };
        if (oauthRes.nav === "back") return { nav: "back" };
        oauthRaw = oauthRes.value ?? "";

        while (true) {
          const apiRes = await inputWithBack(
            `${vendorTitle} API key account labels (comma-separated, e.g. work, personal)`,
            apiRaw,
          );
          if (apiRes.nav === "cancel") return { nav: "cancel" };
          if (apiRes.nav === "back") break;
          apiRaw = apiRes.value ?? "";

          const oauthLabels = oauthRaw
            .split(",")
            .map((s: string) => s.trim())
            .filter(Boolean);
          const apiLabels = apiRaw
            .split(",")
            .map((s: string) => s.trim())
            .filter(Boolean);

          const apiEnvByLabel = new Map<string, string>();
          for (const label of apiLabels) {
            const existingEnv = existingApiEnvByLabel.get(label);
            apiEnvByLabel.set(label, existingEnv ?? defaultApiEnvVar(vendor, label));
          }

          let goBackToApiLabels = false;
          let idx = 0;
          while (idx < apiLabels.length) {
            const label = apiLabels[idx];
            const envDefault = apiEnvByLabel.get(label) ?? defaultApiEnvVar(vendor, label);
            const envRes = await inputWithBack(
              `${vendorTitle} env var for API key '${label}'`,
              envDefault,
            );
            if (envRes.nav === "cancel") return { nav: "cancel" };
            if (envRes.nav === "back") {
              if (idx === 0) {
                goBackToApiLabels = true;
                break;
              }
              idx -= 1;
              continue;
            }

            apiEnvByLabel.set(label, (envRes.value ?? "").trim() || envDefault);
            idx += 1;
          }

          if (goBackToApiLabels) {
            continue;
          }

          const routes: RouteConfig[] = [];

          for (const label of oauthLabels) {
            const key = `oauth::${label.toLowerCase()}`;
            routes.push({
              id: existingRouteIdByKey.get(key),
              auth_type: "oauth",
              label,
              provider_id: generateOauthProviderId(vendor, label),
            });
          }

          for (const label of apiLabels) {
            const key = `api_key::${label.toLowerCase()}`;
            routes.push({
              id: existingRouteIdByKey.get(key),
              auth_type: "api_key",
              label,
              provider_id: defaultProviderId(vendor, "api_key"),
              api_key_env: apiEnvByLabel.get(label) ?? defaultApiEnvVar(vendor, label),
            });
          }

          if (routes.length === 0) {
            const emptyChoice = await ctx.ui.select(
              `No routes configured for ${vendorTitle}.`,
              ["Retry", "Skip vendor", "← Back", "Cancel"],
            );
            if (!emptyChoice || emptyChoice === "Cancel") return { nav: "cancel" };
            if (emptyChoice === "← Back") return { nav: "back" };
            if (emptyChoice === "Skip vendor") return { nav: "ok", config: undefined };
            continue;
          }

          return {
            nav: "ok",
            config: {
              vendor,
              routes,
              oauth_cooldown_minutes: Number(existing?.oauth_cooldown_minutes ?? 180),
              api_key_cooldown_minutes: Number(existing?.api_key_cooldown_minutes ?? 15),
              auto_retry: existing?.auto_retry ?? true,
            },
          };
        }
      }
    }

    async function orderVendorRoutes(vendor: "openai" | "claude"): Promise<WizardNav> {
      const vendorCfg = vendorConfigs.get(vendor);
      if (!vendorCfg || !Array.isArray(vendorCfg.routes)) return "ok";
      const routes = vendorCfg.routes;
      if (routes.length <= 1) return "ok";

      const vendorTitle = titleCase(vendor);

      while (true) {
        const summary = routes
          .map((r, i) => `${i + 1}. ${String(r.auth_type)} · ${decode(String(r.label ?? ""))}`)
          .join("\n");

        const orderChoice = await ctx.ui.select(
          `${vendorTitle} route order (first = preferred within vendor):\n${summary}`,
          ["Keep order", "Move route", "← Back", "Cancel"],
        );

        if (!orderChoice || orderChoice === "Cancel") return "cancel";
        if (orderChoice === "← Back") return "back";
        if (orderChoice === "Keep order") return "ok";

        const routeOptions = routes.map(
          (r, i) => `${i + 1}. ${String(r.auth_type)} · ${decode(String(r.label ?? ""))}`,
        );

        const fromChoice = await ctx.ui.select(`Move which route? (${vendorTitle})`, [
          ...routeOptions,
          "← Back",
          "Cancel",
        ]);
        if (!fromChoice || fromChoice === "Cancel") return "cancel";
        if (fromChoice === "← Back") continue;

        const fromIndex = routeOptions.indexOf(fromChoice);
        if (fromIndex < 0) continue;

        const toChoice = await ctx.ui.select(`Move to which position? (${vendorTitle})`, [
          ...routeOptions,
          "← Back",
          "Cancel",
        ]);
        if (!toChoice || toChoice === "Cancel") return "cancel";
        if (toChoice === "← Back") continue;

        const toIndex = routeOptions.indexOf(toChoice);
        if (toIndex < 0 || toIndex === fromIndex) continue;

        const [picked] = routes.splice(fromIndex, 1);
        routes.splice(toIndex, 0, picked);
      }
    }

    let targetPath = preferredWritableConfigPath(ctx.cwd);
    let useOpenAI = true;
    let useClaude = false;

    const existingCfg = cfg ?? loadConfig(ctx.cwd);
    if (existingCfg.vendors.some((v) => v.vendor === "openai")) useOpenAI = true;
    if (existingCfg.vendors.some((v) => v.vendor === "claude" || v.vendor === "anthropic")) {
      useClaude = true;
    }

    const vendorConfigs = new Map<string, VendorConfig>();

    const existingOpenAI = existingCfg.vendors.find((v) => v.vendor === "openai");
    if (existingOpenAI) {
      vendorConfigs.set("openai", {
        vendor: "openai",
        routes: existingOpenAI.routes.map((r) => ({
          id: r.id,
          auth_type: r.auth_type,
          label: r.label,
          provider_id: r.provider_id,
          api_key_env: r.api_key_env,
          api_key_path: r.api_key_path,
          api_key: r.api_key,
          openai_org_id_env: r.openai_org_id_env,
          openai_project_id_env: r.openai_project_id_env,
          cooldown_minutes: r.cooldown_minutes,
        })),
        oauth_cooldown_minutes: existingOpenAI.oauth_cooldown_minutes,
        api_key_cooldown_minutes: existingOpenAI.api_key_cooldown_minutes,
        auto_retry: existingOpenAI.auto_retry,
      });
    }

    const existingClaude = existingCfg.vendors.find((v) => v.vendor === "claude" || v.vendor === "anthropic");
    if (existingClaude) {
      vendorConfigs.set("claude", {
        vendor: "claude",
        routes: existingClaude.routes.map((r) => ({
          id: r.id,
          auth_type: r.auth_type,
          label: r.label,
          provider_id: r.provider_id,
          api_key_env: r.api_key_env,
          api_key_path: r.api_key_path,
          api_key: r.api_key,
          cooldown_minutes: r.cooldown_minutes,
        })),
        oauth_cooldown_minutes: existingClaude.oauth_cooldown_minutes,
        api_key_cooldown_minutes: existingClaude.api_key_cooldown_minutes,
        auto_retry: existingClaude.auto_retry,
      });
    }

    let defaultVendorChoice = existingCfg.default_vendor;
    let failoverScope: FailoverScope = existingCfg.failover.scope;
    let returnEnabled = existingCfg.failover.return_to_preferred.enabled;
    let returnStableMinutes = existingCfg.failover.return_to_preferred.min_stable_minutes;
    let triggerRateLimit = existingCfg.failover.triggers.rate_limit;
    let triggerQuota = existingCfg.failover.triggers.quota_exhausted;
    let triggerAuth = existingCfg.failover.triggers.auth_error;
    let preferenceStackDraft: PreferenceStackEntryConfig[] = existingCfg.preference_stack.map((entry) => ({
      route_id: entry.route_id,
      model: entry.model,
    }));

    function draftVendorList(): VendorConfig[] {
      return Array.from(vendorConfigs.values());
    }

    function buildDraftNormalized(defaultVendor: string): NormalizedConfig {
      return normalizeConfig({
        enabled: true,
        default_vendor: defaultVendor,
        vendors: draftVendorList(),
        rate_limit_patterns: cfg?.rate_limit_patterns ?? [],
        failover: {
          scope: failoverScope,
          return_to_preferred: {
            enabled: returnEnabled,
            min_stable_minutes: returnStableMinutes,
          },
          triggers: {
            rate_limit: triggerRateLimit,
            quota_exhausted: triggerQuota,
            auth_error: triggerAuth,
          },
        },
        preference_stack: preferenceStackDraft,
      });
    }

    function previewRouteLabel(preview: NormalizedConfig, routeId: string): string {
      for (const v of preview.vendors) {
        for (const route of v.routes) {
          if (route.id === routeId) {
            return `${routeDisplay(v.vendor, route)} [${route.id}]`;
          }
        }
      }
      return `[missing route_id=${routeId}]`;
    }

    async function configurePreferenceStack(defaultVendor: string): Promise<WizardNav> {
      while (true) {
        const preview = buildDraftNormalized(defaultVendor);
        preferenceStackDraft = preview.preference_stack.map((entry) => ({
          route_id: entry.route_id,
          model: entry.model,
        }));

        const summary = preview.preference_stack
          .map(
            (entry, i) =>
              `${i + 1}. ${previewRouteLabel(preview, entry.route_id)} model=${entry.model ?? "current"}`,
          )
          .join("\n");

        const choice = await ctx.ui.select(
          `Preference stack (top is most preferred):\n${summary}`,
          [
            "Keep stack",
            "Move entry",
            "Set model override",
            "Reset recommended",
            "← Back",
            "Cancel",
          ],
        );

        if (!choice || choice === "Cancel") return "cancel";
        if (choice === "← Back") return "back";
        if (choice === "Keep stack") return "ok";

        if (choice === "Reset recommended") {
          preferenceStackDraft = [];
          continue;
        }

        const entryOptions = preview.preference_stack.map(
          (entry, i) =>
            `${i + 1}. ${previewRouteLabel(preview, entry.route_id)} model=${entry.model ?? "current"}`,
        );

        if (choice === "Move entry") {
          if (entryOptions.length < 2) {
            ctx.ui.notify(`[${EXT}] Need at least 2 entries to reorder`, "warning");
            continue;
          }

          const fromChoice = await ctx.ui.select("Move which stack entry?", [
            ...entryOptions,
            "← Back",
            "Cancel",
          ]);
          if (!fromChoice || fromChoice === "Cancel") return "cancel";
          if (fromChoice === "← Back") continue;

          const fromIndex = entryOptions.indexOf(fromChoice);
          if (fromIndex < 0) continue;

          const toChoice = await ctx.ui.select("Move to which position?", [
            ...entryOptions,
            "← Back",
            "Cancel",
          ]);
          if (!toChoice || toChoice === "Cancel") return "cancel";
          if (toChoice === "← Back") continue;

          const toIndex = entryOptions.indexOf(toChoice);
          if (toIndex < 0 || toIndex === fromIndex) continue;

          const [picked] = preferenceStackDraft.splice(fromIndex, 1);
          preferenceStackDraft.splice(toIndex, 0, picked);
          continue;
        }

        if (choice === "Set model override") {
          const targetChoice = await ctx.ui.select("Set model for which stack entry?", [
            ...entryOptions,
            "← Back",
            "Cancel",
          ]);
          if (!targetChoice || targetChoice === "Cancel") return "cancel";
          if (targetChoice === "← Back") continue;

          const targetIndex = entryOptions.indexOf(targetChoice);
          if (targetIndex < 0) continue;

          const currentModel = preferenceStackDraft[targetIndex]?.model ?? "";
          const modelRes = await inputWithBack(
            "Model override (type 'current' to clear override and follow /model)",
            currentModel,
          );
          if (modelRes.nav === "cancel") return "cancel";
          if (modelRes.nav === "back") continue;

          const trimmed = String(modelRes.value ?? "").trim();
          if (
            trimmed.toLowerCase() === "current" ||
            trimmed.toLowerCase() === "follow_current" ||
            trimmed.toLowerCase() === "none"
          ) {
            preferenceStackDraft[targetIndex] = {
              route_id: preferenceStackDraft[targetIndex].route_id,
            };
          } else if (trimmed) {
            preferenceStackDraft[targetIndex] = {
              ...preferenceStackDraft[targetIndex],
              model: trimmed,
            };
          }
        }
      }
    }

    let stage: "dest" | "vendors" | "routes" | "order" | "default" | "policy" | "stack" = "dest";

    while (true) {
      if (stage === "dest") {
        const globalDest = `Global (${globalConfigPath()})`;
        const projectDest = `Project (${projectConfigPath(ctx.cwd)})`;
        const preferProject = targetPath === projectConfigPath(ctx.cwd);

        const destChoice = await ctx.ui.select(
          "Where should subswitch config live?",
          preferProject ? [projectDest, globalDest, "Cancel"] : [globalDest, projectDest, "Cancel"],
        );

        if (!destChoice || destChoice === "Cancel") {
          ctx.ui.notify(`[${EXT}] Setup cancelled`, "warning");
          return;
        }

        targetPath = destChoice === projectDest
          ? projectConfigPath(ctx.cwd)
          : globalConfigPath();

        stage = "vendors";
        continue;
      }

      if (stage === "vendors") {
        const choice = await ctx.ui.select("Select vendors to configure", [
          "Continue",
          `OpenAI: ${useOpenAI ? "Yes" : "No"}`,
          `Claude: ${useClaude ? "Yes" : "No"}`,
          "← Back",
          "Cancel",
        ]);

        if (!choice || choice === "Cancel") {
          ctx.ui.notify(`[${EXT}] Setup cancelled`, "warning");
          return;
        }

        if (choice.startsWith("OpenAI:")) {
          useOpenAI = !useOpenAI;
          if (!useOpenAI) vendorConfigs.delete("openai");
          continue;
        }

        if (choice.startsWith("Claude:")) {
          useClaude = !useClaude;
          if (!useClaude) vendorConfigs.delete("claude");
          continue;
        }

        if (choice === "← Back") {
          stage = "dest";
          continue;
        }

        if (!useOpenAI && !useClaude) {
          ctx.ui.notify(`[${EXT}] Select at least one vendor`, "warning");
          continue;
        }

        stage = "routes";
        continue;
      }

      if (stage === "routes") {
        if (useOpenAI) {
          const openaiResult = await collectVendor("openai", vendorConfigs.get("openai"));
          if (openaiResult.nav === "cancel") {
            ctx.ui.notify(`[${EXT}] Setup cancelled`, "warning");
            return;
          }
          if (openaiResult.nav === "back") {
            stage = "vendors";
            continue;
          }
          if (openaiResult.config) vendorConfigs.set("openai", openaiResult.config);
          else vendorConfigs.delete("openai");
        }

        if (useClaude) {
          const claudeResult = await collectVendor("claude", vendorConfigs.get("claude"));
          if (claudeResult.nav === "cancel") {
            ctx.ui.notify(`[${EXT}] Setup cancelled`, "warning");
            return;
          }
          if (claudeResult.nav === "back") {
            stage = "vendors";
            continue;
          }
          if (claudeResult.config) vendorConfigs.set("claude", claudeResult.config);
          else vendorConfigs.delete("claude");
        }

        if (vendorConfigs.size === 0) {
          ctx.ui.notify(`[${EXT}] No routes configured; returning to vendor selection`, "warning");
          stage = "vendors";
          continue;
        }

        stage = "order";
        continue;
      }

      if (stage === "order") {
        if (useOpenAI && vendorConfigs.has("openai")) {
          const nav = await orderVendorRoutes("openai");
          if (nav === "cancel") {
            ctx.ui.notify(`[${EXT}] Setup cancelled`, "warning");
            return;
          }
          if (nav === "back") {
            stage = "routes";
            continue;
          }
        }

        if (useClaude && vendorConfigs.has("claude")) {
          const nav = await orderVendorRoutes("claude");
          if (nav === "cancel") {
            ctx.ui.notify(`[${EXT}] Setup cancelled`, "warning");
            return;
          }
          if (nav === "back") {
            stage = "routes";
            continue;
          }
        }

        stage = "default";
        continue;
      }

      if (stage === "default") {
        const vendorNames = Array.from(vendorConfigs.keys());
        if (vendorNames.length === 0) {
          stage = "vendors";
          continue;
        }

        if (!vendorNames.includes(defaultVendorChoice)) {
          defaultVendorChoice = vendorNames[0];
        }

        const orderedVendorNames = [
          defaultVendorChoice,
          ...vendorNames.filter((v) => v !== defaultVendorChoice),
        ];

        const defaultChoice = await ctx.ui.select("Default vendor", [
          ...orderedVendorNames,
          "← Back",
          "Cancel",
        ]);

        if (!defaultChoice || defaultChoice === "Cancel") {
          ctx.ui.notify(`[${EXT}] Setup cancelled`, "warning");
          return;
        }

        if (defaultChoice === "← Back") {
          stage = "order";
          continue;
        }

        defaultVendorChoice = defaultChoice;
        stage = "policy";
        continue;
      }

      if (stage === "policy") {
        const policyChoice = await ctx.ui.select("Failover policy", [
          "Continue",
          `Scope: ${failoverScope === "global" ? "Cross-vendor" : "Current vendor only"}`,
          `Return to preferred: ${returnEnabled ? "On" : "Off"}`,
          `Minimum time on fallback (minutes): ${returnStableMinutes}`,
          `Failover on rate limit: ${triggerRateLimit ? "On" : "Off"}`,
          `Failover on exhausted quota: ${triggerQuota ? "On" : "Off"}`,
          `Failover on auth error (API key routes): ${triggerAuth ? "On" : "Off"}`,
          "← Back",
          "Cancel",
        ]);

        if (!policyChoice || policyChoice === "Cancel") {
          ctx.ui.notify(`[${EXT}] Setup cancelled`, "warning");
          return;
        }

        if (policyChoice === "← Back") {
          stage = "default";
          continue;
        }

        if (policyChoice.startsWith("Scope:")) {
          failoverScope = failoverScope === "global" ? "current_vendor" : "global";
          continue;
        }

        if (policyChoice.startsWith("Return to preferred:")) {
          returnEnabled = !returnEnabled;
          continue;
        }

        if (policyChoice.startsWith("Minimum time on fallback (minutes):")) {
          const minutesRes = await inputWithBack(
            "Minimum time on fallback in minutes (0 = no holdoff)",
            String(returnStableMinutes),
          );
          if (minutesRes.nav === "cancel") {
            ctx.ui.notify(`[${EXT}] Setup cancelled`, "warning");
            return;
          }
          if (minutesRes.nav === "back") continue;

          const parsed = Number(String(minutesRes.value ?? "").trim());
          if (!Number.isFinite(parsed) || parsed < 0) {
            ctx.ui.notify(`[${EXT}] Enter a non-negative integer`, "warning");
            continue;
          }
          returnStableMinutes = Math.floor(parsed);
          continue;
        }

        if (policyChoice.startsWith("Failover on rate limit:")) {
          triggerRateLimit = !triggerRateLimit;
          continue;
        }

        if (policyChoice.startsWith("Failover on exhausted quota:")) {
          triggerQuota = !triggerQuota;
          continue;
        }

        if (policyChoice.startsWith("Failover on auth error (API key routes):")) {
          triggerAuth = !triggerAuth;
          continue;
        }

        stage = "stack";
        continue;
      }

      const nav = await configurePreferenceStack(defaultVendorChoice);
      if (nav === "cancel") {
        ctx.ui.notify(`[${EXT}] Setup cancelled`, "warning");
        return;
      }
      if (nav === "back") {
        stage = "policy";
        continue;
      }

      const out = buildDraftNormalized(defaultVendorChoice);

      writeJson(targetPath, configToJson(out));

      cfg = out;
      registerAliasesFromConfig(cfg);
      statePath = statePathForConfigPath(ctx.cwd, targetPath);
      pruneRuntimeState();
      persistRuntimeState();

      ctx.ui.notify(`[${EXT}] Wrote config to ${targetPath}`, "info");

      const oauthProviders = configuredOauthProviders();
      if (oauthProviders.length > 0) {
        await promptOauthLogin(ctx, oauthProviders);
      }

      updateStatus(ctx);
      return;
    }
  }

  async function runQuickPicker(ctx: any): Promise<void> {
    if (!ctx.hasUI) {
      notifyStatus(ctx);
      return;
    }

    ensureCfg(ctx);

    const options: string[] = [
      "Status",
      "Long status",
      "Setup wizard",
      "OAuth login checklist",
      "Edit config",
      "Reorder failover stack",
      "Reload config",
    ];

    for (const v of cfg!.vendors) {
      for (const route of v.routes) {
        options.push(`Use: ${routeDisplay(v.vendor, route)}`);
      }
    }

    const selected = await ctx.ui.select("subswitch", options);
    if (!selected) return;

    if (selected === "Status") {
      notifyStatus(ctx, false);
      return;
    }

    if (selected === "Long status") {
      notifyStatus(ctx, true);
      return;
    }

    if (selected === "Setup wizard") {
      await setupWizard(ctx);
      return;
    }

    if (selected === "OAuth login checklist") {
      await promptOauthLogin(ctx, configuredOauthProviders());
      return;
    }

    if (selected === "Edit config") {
      await editConfigInteractive(ctx);
      return;
    }

    if (selected === "Reorder failover stack") {
      await reorderVendorInteractive(ctx);
      return;
    }

    if (selected === "Reload config") {
      reloadCfg(ctx);
      loadRuntimeState(ctx);
      notifyStatus(ctx);
      updateStatus(ctx);
      return;
    }

    if (selected.startsWith("Use: ")) {
      const payload = selected.slice("Use: ".length);
      const parts = payload.split(" · ");
      if (parts.length !== 3) return;

      const vendor = parts[0].trim();
      const authType = parts[1].trim() as AuthType;
      const label = parts[2].trim();
      await useRouteBySelector(ctx, vendor, authType, label, ctx.model?.id, "quick picker");
    }
  }

  function toolStatusSummary(ctx: any, detailed = false): string {
    return buildStatusLines(ctx, detailed).join("\n");
  }

  async function toolPreferRoute(
    ctx: any,
    vendor: string,
    authType: AuthType,
    label: string,
    modelId?: string,
  ): Promise<string> {
    ensureCfg(ctx);

    const ok = routeOrderMoveToFront(vendor, authType, label);
    if (!ok) {
      return `No route found for vendor='${vendor}', auth_type='${authType}', label='${label}'`;
    }

    const savePath = saveCurrentConfig(ctx);

    const targetModel = modelId ?? ctx.model?.id;
    if (targetModel) {
      await useFirstRouteForAuthType(ctx, vendor, authType, label, targetModel, "tool prefer");
    }

    return `Moved ${vendor}/${authType}/${label} to the top of the preference stack and saved config to ${savePath}.`;
  }

  // Register aliases as early as possible (extension load-time).
  registerAliasesFromConfig(loadConfig(process.cwd()));

  pi.registerTool({
    name: "subswitch_manage",
    label: "Subswitch Manage",
    description:
      "Manage subscription/api failover routes for vendors (openai/claude). Supports status/longstatus, use, prefer, rename, reload.",
    parameters: Type.Object({
      action: Type.Union([
        Type.Literal("status"),
        Type.Literal("longstatus"),
        Type.Literal("use"),
        Type.Literal("prefer"),
        Type.Literal("rename"),
        Type.Literal("reload"),
      ]),
      vendor: Type.Optional(Type.String({ description: "Vendor, e.g. openai or claude" })),
      auth_type: Type.Optional(
        Type.Union([Type.Literal("oauth"), Type.Literal("api_key")], {
          description: "Auth type",
        }),
      ),
      label: Type.Optional(Type.String({ description: "Route label, e.g. work/personal" })),
      model_id: Type.Optional(Type.String({ description: "Optional model id to switch to while applying route" })),
      old_label: Type.Optional(Type.String({ description: "Old label for rename action" })),
      new_label: Type.Optional(Type.String({ description: "New label for rename action" })),
    }),
    async execute(_toolCallId, params: any, _signal, _onUpdate, ctx) {
      ensureCfg(ctx);
      lastCtx = ctx;

      const action = String(params.action ?? "").trim();

      if (action === "status") {
        const text = toolStatusSummary(ctx, false);
        return {
          content: [{ type: "text", text }],
          details: { action, ok: true },
        };
      }

      if (action === "longstatus") {
        const text = toolStatusSummary(ctx, true);
        return {
          content: [{ type: "text", text }],
          details: { action, ok: true },
        };
      }

      if (action === "reload") {
        reloadCfg(ctx);
        loadRuntimeState(ctx);
        updateStatus(ctx);
        const text = `Reloaded config and runtime state.\n${toolStatusSummary(ctx, false)}`;
        return {
          content: [{ type: "text", text }],
          details: { action, ok: true },
        };
      }

      if (action === "use") {
        const vendor = String(params.vendor ?? "").trim().toLowerCase();
        const authType = String(params.auth_type ?? "").trim() as AuthType;
        const label = String(params.label ?? "").trim();
        const modelId = params.model_id ? String(params.model_id).trim() : undefined;

        if (!vendor || (authType !== "oauth" && authType !== "api_key") || !label) {
          return {
            content: [
              {
                type: "text",
                text:
                  "Missing required args for action=use: vendor, auth_type (oauth|api_key), label",
              },
            ],
            details: { action, ok: false },
          };
        }

        const ok = await useRouteBySelector(ctx, vendor, authType, label, modelId, "tool use");
        return {
          content: [
            {
              type: "text",
              text: ok
                ? `Switched to ${vendor}/${authType}/${label}${modelId ? ` with model ${modelId}` : ""}.`
                : `Failed to switch to ${vendor}/${authType}/${label}.`,
            },
          ],
          details: { action, ok },
        };
      }

      if (action === "prefer") {
        const vendor = String(params.vendor ?? "").trim().toLowerCase();
        const authType = String(params.auth_type ?? "").trim() as AuthType;
        const label = String(params.label ?? "").trim();
        const modelId = params.model_id ? String(params.model_id).trim() : undefined;

        if (!vendor || (authType !== "oauth" && authType !== "api_key") || !label) {
          return {
            content: [
              {
                type: "text",
                text:
                  "Missing required args for action=prefer: vendor, auth_type (oauth|api_key), label",
              },
            ],
            details: { action, ok: false },
          };
        }

        const text = await toolPreferRoute(ctx, vendor, authType, label, modelId);
        return {
          content: [{ type: "text", text }],
          details: { action, ok: !text.startsWith("No route found") },
        };
      }

      if (action === "rename") {
        const vendor = String(params.vendor ?? "").trim().toLowerCase();
        const authType = String(params.auth_type ?? "").trim() as AuthType;
        const oldLabel = String(params.old_label ?? "").trim();
        const newLabel = String(params.new_label ?? "").trim();

        if (
          !vendor ||
          (authType !== "oauth" && authType !== "api_key") ||
          !oldLabel ||
          !newLabel
        ) {
          return {
            content: [
              {
                type: "text",
                text:
                  "Missing required args for action=rename: vendor, auth_type (oauth|api_key), old_label, new_label",
              },
            ],
            details: { action, ok: false },
          };
        }

        const ok = renameRoute(vendor, authType, oldLabel, newLabel);
        if (!ok) {
          return {
            content: [
              {
                type: "text",
                text: `Route not found for rename (${vendor}/${authType}/${oldLabel})`,
              },
            ],
            details: { action, ok: false },
          };
        }

        const savePath = saveCurrentConfig(ctx);
        return {
          content: [
            {
              type: "text",
              text: `Renamed route '${oldLabel}' -> '${newLabel}' and saved config to ${savePath}.`,
            },
          ],
          details: { action, ok: true },
        };
      }

      return {
        content: [
          {
            type: "text",
            text: `Unknown action '${action}'. Supported: status, longstatus, use, prefer, rename, reload.`,
          },
        ],
        details: { action, ok: false },
      };
    },
  });

  pi.registerCommand("subswitch", {
    description:
      "Vendor/account failover manager (openai/claude). Use /subswitch for quick picker + status.",
    handler: async (args, ctx) => {
      ensureCfg(ctx);
      lastCtx = ctx;
      rememberActiveFromCtx(ctx);
      managedModelId = ctx.model?.id;

      const parts = splitArgs(args || "");
      const cmd = parts[0] ?? "";

      if (cmd === "" || cmd === "status" || cmd === "longstatus") {
        if (cmd === "") {
          await runQuickPicker(ctx);
        } else {
          notifyStatus(ctx, cmd === "longstatus");
        }
        await refreshOauthReminderWidget(ctx, configuredOauthProviders());
        updateStatus(ctx);
        return;
      }

      if (cmd === "help") {
        if (ctx.hasUI) {
          const help =
            "Usage: /subswitch [command]\n\n" +
            "Commands:\n" +
            "  (no args)                     Quick picker + status\n" +
            "  status                        Show concise status\n" +
            "  longstatus                    Show detailed status (stack/models/ids)\n" +
            "  setup                         Guided setup wizard (applies only on finish)\n" +
            "  login                         Prompt OAuth login checklist and prefill /login\n" +
            "  login-status                  Re-check OAuth login completion and update reminder\n" +
            "  reload                        Reload config + runtime state\n" +
            "  on / off                      Enable/disable extension (runtime)\n" +
            "  reorder [vendor]              Interactive reorder for failover preference stack\n" +
            "  edit                          Edit JSON config with validation\n" +
            "  models <vendor>               Show compatible models across routes\n" +
            "  use <vendor> <auth_type> <label> [modelId]\n" +
            "  subscription <vendor> [label] [modelId]\n" +
            "  api <vendor> [label] [modelId]\n" +
            "  rename <vendor> <auth_type> <old_label> <new_label>\n" +
            "\nCompatibility aliases:\n" +
            "  primary [label] [modelId]     == subscription <default_vendor> ...\n" +
            "  fallback [label] [modelId]    == api <default_vendor> ...";
          ctx.ui.notify(help, "info");
        }
        updateStatus(ctx);
        return;
      }

      if (cmd === "setup") {
        await setupWizard(ctx);
        updateStatus(ctx);
        return;
      }

      if (cmd === "login") {
        await promptOauthLogin(ctx, configuredOauthProviders());
        updateStatus(ctx);
        return;
      }

      if (cmd === "login-status") {
        const providers = configuredOauthProviders();
        const missing = await refreshOauthReminderWidget(ctx, providers);
        if (ctx.hasUI) {
          if (missing.length === 0) {
            ctx.ui.notify(`[${EXT}] OAuth login checklist complete`, "info");
          } else {
            ctx.ui.notify(
              `[${EXT}] Missing OAuth login for: ${missing.join(", ")}`,
              "warning",
            );
          }
        }
        updateStatus(ctx);
        return;
      }

      if (cmd === "reload") {
        reloadCfg(ctx);
        loadRuntimeState(ctx);
        notifyStatus(ctx);
        updateStatus(ctx);
        return;
      }

      if (cmd === "on") {
        if (cfg) cfg.enabled = true;
        if (ctx.hasUI) ctx.ui.notify(`[${EXT}] enabled=true (runtime)`, "info");
        updateStatus(ctx);
        return;
      }

      if (cmd === "off") {
        if (cfg) cfg.enabled = false;
        clearRetryTimer();
        restoreOriginalEnv();
        pendingOauthReminderProviders = [];
        if (ctx.hasUI) {
          ctx.ui.notify(`[${EXT}] enabled=false (runtime)`, "warning");
          ctx.ui.setStatus(EXT, undefined);
          ctx.ui.setWidget(LOGIN_WIDGET_KEY, undefined);
        }
        return;
      }

      if (cmd === "use") {
        const vendor = String(parts[1] ?? "").trim().toLowerCase();
        const authType = String(parts[2] ?? "").trim() as AuthType;
        const label = String(parts[3] ?? "").trim();
        const modelId = parts[4] ? String(parts[4]).trim() : undefined;

        if (!vendor || (authType !== "oauth" && authType !== "api_key") || !label) {
          if (ctx.hasUI) {
            ctx.ui.notify(
              `[${EXT}] Usage: /subswitch use <vendor> <auth_type> <label> [modelId]`,
              "warning",
            );
          }
          updateStatus(ctx);
          return;
        }

        await useRouteBySelector(ctx, vendor, authType, label, modelId, "manual use");
        updateStatus(ctx);
        return;
      }

      if (cmd === "subscription" || cmd === "api") {
        const authType: AuthType = cmd === "subscription" ? "oauth" : "api_key";
        const vendor = vendorForCommand(ctx, parts[1]);
        const label = parts[2] ? String(parts[2]).trim() : undefined;
        const modelId = parts[3] ? String(parts[3]).trim() : undefined;

        await useFirstRouteForAuthType(ctx, vendor, authType, label, modelId, "manual auth-type");
        updateStatus(ctx);
        return;
      }

      if (cmd === "primary" || cmd === "fallback") {
        const authType: AuthType = cmd === "primary" ? "oauth" : "api_key";
        const vendor = cfg?.default_vendor ?? "openai";
        const label = parts[1] ? String(parts[1]).trim() : undefined;
        const modelId = parts[2] ? String(parts[2]).trim() : undefined;

        if (ctx.hasUI) {
          const replacement = cmd === "primary" ? "subscription" : "api";
          ctx.ui.notify(
            `[${EXT}] '${cmd}' is deprecated; use '/subswitch ${replacement} ${vendor} ...'`,
            "warning",
          );
        }

        await useFirstRouteForAuthType(ctx, vendor, authType, label, modelId, "compat alias");
        updateStatus(ctx);
        return;
      }

      if (cmd === "rename") {
        const vendor = String(parts[1] ?? "").trim().toLowerCase();
        const authType = String(parts[2] ?? "").trim() as AuthType;
        const oldLabel = String(parts[3] ?? "").trim();
        const newLabel = String(parts[4] ?? "").trim();

        if (!vendor || (authType !== "oauth" && authType !== "api_key") || !oldLabel || !newLabel) {
          if (ctx.hasUI) {
            ctx.ui.notify(
              `[${EXT}] Usage: /subswitch rename <vendor> <auth_type> <old_label> <new_label>`,
              "warning",
            );
          }
          updateStatus(ctx);
          return;
        }

        const ok = renameRoute(vendor, authType, oldLabel, newLabel);
        if (!ok) {
          if (ctx.hasUI) {
            ctx.ui.notify(
              `[${EXT}] Route not found for rename (${vendor}/${authType}/${oldLabel})`,
              "warning",
            );
          }
          updateStatus(ctx);
          return;
        }

        const savePath = saveCurrentConfig(ctx);
        if (ctx.hasUI) {
          ctx.ui.notify(
            `[${EXT}] Renamed route '${oldLabel}' -> '${newLabel}'. Saved to ${savePath}`,
            "info",
          );
        }

        reloadCfg(ctx);
        updateStatus(ctx);
        return;
      }

      if (cmd === "reorder") {
        await reorderVendorInteractive(ctx, parts[1]);
        updateStatus(ctx);
        return;
      }

      if (cmd === "edit") {
        await editConfigInteractive(ctx);
        updateStatus(ctx);
        return;
      }

      if (cmd === "models") {
        const vendor = vendorForCommand(ctx, parts[1]);
        await showModelCompatibility(ctx, vendor);
        updateStatus(ctx);
        return;
      }

      if (ctx.hasUI) {
        ctx.ui.notify(`[${EXT}] Unknown command '${cmd}'. Try '/subswitch help'.`, "warning");
      }
      updateStatus(ctx);
    },
  });

  pi.on("input", async (event) => {
    pendingInputSource = event.source as InputSource;
  });

  pi.on("before_agent_start", async (event, ctx) => {
    ensureCfg(ctx);
    if (!cfg?.enabled) return;

    lastCtx = ctx;
    rememberActiveFromCtx(ctx);
    managedModelId = ctx.model?.id;

    lastPrompt = {
      source: pendingInputSource ?? "interactive",
      text: event.prompt,
      images: (event.images ?? []) as any[],
    };
    pendingInputSource = undefined;

    await maybePromotePreferredRoute(ctx, "before turn");
    scheduleRetryTimer(ctx);
    updateStatus(ctx);
  });

  pi.on("model_select", async (event, ctx) => {
    ensureCfg(ctx);
    if (!cfg?.enabled) return;

    lastCtx = ctx;

    const activeProvider = event.model?.provider;
    const activeModelId = event.model?.id;

    const isExtensionSwitch =
      pendingExtensionSwitch !== undefined &&
      activeProvider === pendingExtensionSwitch.provider &&
      activeModelId === pendingExtensionSwitch.modelId;

    if (isExtensionSwitch) {
      pendingExtensionSwitch = undefined;
      rememberActiveFromCtx(ctx);
      managedModelId = activeModelId;
      scheduleRetryTimer(ctx);
      await refreshOauthReminderWidget(ctx, configuredOauthProviders());
      updateStatus(ctx);
      return;
    }

    managedModelId = activeModelId;
    rememberActiveFromCtx(ctx);
    scheduleRetryTimer(ctx);
    await refreshOauthReminderWidget(ctx, configuredOauthProviders());
    updateStatus(ctx);
  });

  pi.on("turn_end", async (event, ctx) => {
    ensureCfg(ctx);
    if (!cfg?.enabled) return;

    lastCtx = ctx;
    rememberActiveFromCtx(ctx);

    const message: any = event.message;
    if (message?.stopReason !== "error") return;

    const err = message?.errorMessage ?? message?.details?.error ?? message?.error ?? "unknown error";

    const provider = ctx.model?.provider;
    const modelId = ctx.model?.id;
    if (!provider || !modelId) return;

    const resolved = resolveVendorRouteForProvider(provider);
    if (!resolved) return;

    const vendorCfg = getVendor(resolved.vendor);
    const route = getRoute(resolved.vendor, resolved.index);
    if (!vendorCfg || !route) return;

    const triggeredByRateLimit =
      cfg.failover.triggers.rate_limit && isRateLimitSignalError(err, cfg.rate_limit_patterns);
    const triggeredByQuota = cfg.failover.triggers.quota_exhausted && isQuotaExhaustedError(err);
    const triggeredByAuth =
      cfg.failover.triggers.auth_error &&
      route.auth_type === "api_key" &&
      isAuthError(err);

    if (!triggeredByRateLimit && !triggeredByQuota && !triggeredByAuth) return;

    const parsedRetryMs = triggeredByAuth ? undefined : parseRetryAfterMs(err);
    const defaultCooldownMs = routeDefaultCooldownMinutes(vendorCfg, route) * 60_000;
    const bufferMs = route.auth_type === "oauth" ? 15_000 : 5_000;
    const until = now() + (parsedRetryMs ?? defaultCooldownMs) + bufferMs;
    setRouteCooldownUntil(resolved.vendor, resolved.index, until);

    const effective = buildEffectivePreferenceStack(resolved.vendor, modelId);
    const currentIdx = findCurrentEffectiveStackIndex(effective, route.id, modelId);
    const start = currentIdx === undefined ? 0 : currentIdx + 1;

    let nextEntry: EffectivePreferenceEntry | undefined;
    for (let i = start; i < effective.length; i++) {
      const candidate = effective[i];
      if (routeEligibleRef(ctx, candidate.route_ref, candidate.model_id)) {
        nextEntry = candidate;
        break;
      }
    }

    const triggerLabel = triggeredByAuth
      ? "auth error"
      : triggeredByQuota
        ? "quota exhausted"
        : "rate limited";

    if (!nextEntry) {
      if (ctx.hasUI) {
        const mins = Math.max(0, Math.ceil((until - now()) / 60000));
        ctx.ui.notify(
          `[${EXT}] ${routeDisplay(resolved.vendor, route)} ${triggerLabel}; no eligible lower-priority entry in preference stack (retry ~${mins}m)`,
          "warning",
        );
      }
      scheduleRetryTimer(ctx);
      updateStatus(ctx);
      return;
    }

    if (ctx.hasUI) {
      const source = parsedRetryMs !== undefined ? "provider retry hint" : "configured cooldown";
      ctx.ui.notify(
        `[${EXT}] ${routeDisplay(resolved.vendor, route)} ${triggerLabel}; switching to ${routeDisplay(nextEntry.route_ref.vendor, nextEntry.route_ref.route)} (${nextEntry.model_id}, ${source})`,
        "warning",
      );
    }

    const switched = await switchToRoute(
      ctx,
      nextEntry.route_ref.vendor,
      nextEntry.route_ref.index,
      nextEntry.model_id,
      triggerLabel,
      true,
    );

    if (!switched) {
      scheduleRetryTimer(ctx);
      updateStatus(ctx);
      return;
    }

    if (cfg.failover.return_to_preferred.enabled) {
      const holdoffMs = cfg.failover.return_to_preferred.min_stable_minutes * 60_000;
      setNextReturnEligibleAtMs(Math.max(nextReturnEligibleAtMs, now() + holdoffMs));
    }

    // Auto-retry after any successful automatic failover switch when enabled.
    if (vendorCfg.auto_retry && lastPrompt && lastPrompt.source !== "extension") {
      const content =
        !lastPrompt.images || lastPrompt.images.length === 0
          ? lastPrompt.text
          : [{ type: "text", text: lastPrompt.text }, ...lastPrompt.images];

      if (typeof ctx.isIdle === "function" && ctx.isIdle()) {
        pi.sendUserMessage(content);
      } else {
        pi.sendUserMessage(content, { deliverAs: "followUp" });
      }
    }

    scheduleRetryTimer(ctx);
    updateStatus(ctx);
  });

  pi.on("session_start", async (_event, ctx) => {
    reloadCfg(ctx);
    loadRuntimeState(ctx);
    lastCtx = ctx;
    rememberActiveFromCtx(ctx);
    managedModelId = ctx.model?.id;

    // If we start on an api_key route we might need to apply env material now.
    const provider = ctx.model?.provider;
    if (provider) {
      const resolved = resolveVendorRouteForProvider(provider);
      if (resolved) {
        const route = getRoute(resolved.vendor, resolved.index);
        if (route?.auth_type === "api_key") {
          applyApiRouteCredentials(resolved.vendor, route);
        }
      }
    }

    scheduleRetryTimer(ctx);
    await refreshOauthReminderWidget(ctx, configuredOauthProviders());
    updateStatus(ctx);
  });

  pi.on("session_switch", async (_event, ctx) => {
    reloadCfg(ctx);
    loadRuntimeState(ctx);
    lastCtx = ctx;
    rememberActiveFromCtx(ctx);
    managedModelId = ctx.model?.id;
    scheduleRetryTimer(ctx);
    await refreshOauthReminderWidget(ctx, configuredOauthProviders());
    updateStatus(ctx);
  });

  pi.on("session_shutdown", async () => {
    persistRuntimeState();
    clearRetryTimer();
    restoreOriginalEnv();
  });
}
