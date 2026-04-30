import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

// GitHub Copilot quota endpoint
interface GitHubCopilotQuotaSnapshot {
  entitlement?: number;
  percent_remaining?: number;
  remaining?: number;
  unlimited?: boolean;
  timestamp_utc?: string;
}

interface GitHubCopilotUserResponse {
  quota_reset_date_utc?: string;
  quota_snapshots?: {
    premium_interactions?: GitHubCopilotQuotaSnapshot;
    chat?: GitHubCopilotQuotaSnapshot;
    completions?: GitHubCopilotQuotaSnapshot;
  };
}
type Provider = "github-copilot" | "zai" | string;

// Auth config (~/.pi/agent/auth.json)
interface AuthConfig {
  "github-copilot"?: {
    refresh?: string;
    enterpriseUrl?: string;
  };
}

// Models config (~/.pi/agent/models.json)
interface ModelsConfig {
  providers?: {
    zai?: {
      baseUrl?: string;
      apiKey?: string;
    };
  };
}

// Z.ai quota endpoint response
interface ZaiQuotaWindow {
  type: string;
  unit: number;
  number: number;
  percentage: number;
  usage?: number;
  currentValue?: number;
  remaining?: number;
  nextResetTime?: number;
}

interface ZaiQuotaLimit {
  code?: number;
  msg?: string;
  data?: {
    limits: ZaiQuotaWindow[];
    level?: string;
  };
  success?: boolean;
}

type QuotaInfo = {
  statusText: string;
  notify?: { message: string; type: "info" | "warning" | "error" };
};

type ThemeColor = "muted" | "error" | "warning" | "success" | "dim";

type ThemeLike = {
  fg: (color: ThemeColor, text: string) => string;
};

const PI_AUTH_PATH = join(homedir(), ".pi", "agent", "auth.json");

const PI_MODELS_PATH = join(homedir(), ".pi", "agent", "models.json");
const FETCH_TIMEOUT_MS = 10_000;
const MODEL_QUOTA_DEBUG = process.env.PI_MODEL_QUOTA_DEBUG === "1";

export default function (pi: ExtensionAPI) {
  // GitHub Copilot cache
  let cachedGitHubCopilotUser: GitHubCopilotUserResponse | null = null;
  let lastGitHubCopilotFetched = 0;

  // Z.ai cache
  let cachedZaiQuota: ZaiQuotaLimit | null = null;
  let lastZaiFetched = 0;
  let modelsData: ModelsConfig | null = null;
  let lastModelsFetched = 0;
  let modelsFetchInFlight: Promise<ModelsConfig | null> | null = null;

  // auth.json cache (shared by all providers)
  let cachedAuthData: AuthConfig | null = null;
  let lastAuthFetched = 0;
  let authFetchInFlight: Promise<AuthConfig | null> | null = null;

  function logDebug(...args: any[]) {
    if (MODEL_QUOTA_DEBUG) console.error(...args);
  }

  let autoRefreshTimer: ReturnType<typeof setInterval> | null = null;

  let activeProvider: Provider | null = null;
  let activeModelId: string | undefined;

  let refreshSeq = 0;
  let lastSuccessfulRefreshAt = 0;
  let lastSuccessfulProvider: Provider | null = null;
  let lastSuccessfulModelId: string | null = null;

  function clearCachesForProvider(provider: Provider) {
    if (provider === "github-copilot") {
      cachedGitHubCopilotUser = null;
      lastGitHubCopilotFetched = 0;
      return;
    }

    if (provider === "zai") {
      cachedZaiQuota = null;
      lastZaiFetched = 0;
      return;
    }
  }

  async function refreshQuotaForActiveModel(
    ctx: ExtensionContext,
    options: { force?: boolean; notify?: boolean } = {},
  ) {
    if (!ctx?.hasUI) return;
    if (!activeProvider) return;

    const seq = ++refreshSeq;

    if (options.force) {
      clearCachesForProvider(activeProvider);
    }

    const quota = await getQuotaForProvider(activeProvider, ctx.ui.theme);

    // Only apply the latest refresh.
    if (seq !== refreshSeq) return;

    if (!quota) {
      ctx.ui.setStatus("model-quota", undefined);
      return;
    }

    ctx.ui.setStatus("model-quota", quota.statusText);

    if (options.notify && quota.notify) {
      ctx.ui.notify(quota.notify.message, quota.notify.type);
    }

    lastSuccessfulRefreshAt = Date.now();
    lastSuccessfulProvider = activeProvider;
    lastSuccessfulModelId = activeModelId ?? null;
  }

  function startAutoRefresh(ctx: ExtensionContext) {
    if (autoRefreshTimer) return;

    autoRefreshTimer = setInterval(
      () => {
        void refreshQuotaForActiveModel(ctx, { force: true, notify: false });
      },
      5 * 60 * 1000,
    );
  }

  pi.on("session_shutdown", async (_event, _ctx) => {
    if (autoRefreshTimer) {
      clearInterval(autoRefreshTimer);
      autoRefreshTimer = null;
    }
  });

  pi.on("session_start", async (_event, ctx) => {
    if (!ctx.hasUI) return;

    // Refresh right away on startup.
    if (ctx.model?.provider) {
      activeProvider = ctx.model.provider;
      activeModelId = ctx.model.id;
      await refreshQuotaForActiveModel(ctx, { force: true, notify: false });
    }

    startAutoRefresh(ctx);
  });

  pi.on("model_select", async (event, ctx) => {
    if (!ctx.hasUI) return;

    activeProvider = event.model.provider;
    activeModelId = event.model.id;

    const alreadyRefreshedOnStartup =
      event.source === "restore" &&
      lastSuccessfulProvider === activeProvider &&
      lastSuccessfulModelId === (activeModelId ?? null) &&
      Date.now() - lastSuccessfulRefreshAt < 2000;

    await refreshQuotaForActiveModel(ctx, {
      force: !alreadyRefreshedOnStartup,
      notify: true,
    });
  });

  // Manual command
  pi.registerCommand("model-quota", {
    description:
      "Show model quota for the current provider (GitHub Copilot + Z.ai supported)",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;

      // Clear caches to get fresh data
      cachedGitHubCopilotUser = null;
      cachedZaiQuota = null;
      lastZaiFetched = 0;
      lastGitHubCopilotFetched = 0;
      cachedAuthData = null;
      lastAuthFetched = 0;
      authFetchInFlight = null;

      // pi extensions don't get direct access to the selected provider inside commands.
      // So we show all providers if available.
      const [copilot, zai] = await Promise.all([
        getQuotaForProvider("github-copilot", ctx.ui.theme),
        getQuotaForProvider("zai", ctx.ui.theme),
      ]);

      const lines: string[] = [];
      if (copilot)
        lines.push(`GitHub Copilot: ${stripAnsiLike(copilot.statusText)}`);
      if (zai) lines.push(`Z.ai: ${stripAnsiLike(zai.statusText)}`);
      if (lines.length === 0) {
        ctx.ui.notify(
          "No quota info available. Make sure you are logged in (OAuth) for GitHub Copilot, or have configured Z.ai API key in models.json",
          "info",
        );
        return;
      }

      ctx.ui.notify(lines.join("\n"), "info");
    },
  });

  async function getQuotaForProvider(
    provider: Provider,
    theme: ThemeLike | undefined,
  ): Promise<QuotaInfo | null> {
    if (provider === "github-copilot") return getGitHubCopilotQuota(theme);
    if (provider === "zai") return getZaiQuota(theme);
    return null;
  }

  function getQuotaNotification(
    percent: number,
    providerName: string,
  ): QuotaInfo["notify"] {
    if (percent >= 100) return undefined;
    if (percent > 95)
      return {
        message: `${providerName} quota nearly exhausted!`,
        type: "error",
      };
    if (percent > 85)
      return { message: `${providerName} quota warning`, type: "warning" };
    return undefined;
  }

  function formatTimeUntil(timestamp: number | string): string {
    const reset =
      typeof timestamp === "string"
        ? new Date(timestamp).getTime()
        : timestamp < 1e12
          ? timestamp * 1000 // unix seconds
          : timestamp; // unix ms
    const diffMs = reset - Date.now();
    if (diffMs <= 0) return "now";

    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffDays > 0) {
      const hours = diffHours % 24;
      return hours > 0 ? `${diffDays}d ${hours}h` : `${diffDays}d`;
    }
    if (diffHours > 0) {
      const mins = diffMins % 60;
      return mins > 0 ? `${diffHours}h ${mins}m` : `${diffHours}h`;
    }
    return `${diffMins}m`;
  }

  function themed(
    theme: ThemeLike | undefined,
    color: ThemeColor,
    text: string,
  ): string {
    return theme ? theme.fg(color, text) : text;
  }

  function formatUsedPercent(
    theme: ThemeLike | undefined,
    pct: number,
  ): string {
    const text = `${pct}%`;
    if (!theme) return text;
    if (pct >= 100) return theme.fg("error", text);
    if (pct > 95) return theme.fg("error", text);
    if (pct > 85) return theme.fg("warning", text);
    return theme.fg("success", text);
  }

  async function getGitHubCopilotQuota(
    theme: ThemeLike | undefined,
  ): Promise<QuotaInfo | null> {
    const user = await fetchGitHubCopilotUser();
    const premium = user?.quota_snapshots?.premium_interactions;
    if (!user || !premium) return null;

    const resetText = user.quota_reset_date_utc
      ? formatTimeUntil(user.quota_reset_date_utc)
      : null;

    const monthlyLabel = themed(theme, "muted", "monthly: ");
    const timePart = resetText ? themed(theme, "dim", ` (${resetText})`) : "";

    if (premium.unlimited) {
      return {
        statusText: `${monthlyLabel}${themed(theme, "success", "unlimited")}${timePart}`,
      };
    }

    let usedPercent: number | null = null;
    if (typeof premium.percent_remaining === "number") {
      usedPercent = Math.round(100 - premium.percent_remaining);
    } else if (
      typeof premium.entitlement === "number" &&
      premium.entitlement > 0 &&
      typeof premium.remaining === "number"
    ) {
      usedPercent = Math.round(
        ((premium.entitlement - premium.remaining) / premium.entitlement) * 100,
      );
    }

    if (usedPercent == null) return null;
    usedPercent = Math.max(0, Math.min(100, usedPercent));

    const status = `${monthlyLabel}${formatUsedPercent(theme, usedPercent)}${timePart}`;

    return {
      statusText: status,
      notify: getQuotaNotification(usedPercent, "GitHub Copilot"),
    };
  }

  async function getZaiQuota(
    theme: ThemeLike | undefined,
  ): Promise<QuotaInfo | null> {
    const quota = await fetchZaiQuota();
    if (!quota?.data?.limits) return null;

    // Z.ai returns two TOKENS_LIMIT windows: session (shorter) and weekly (longer)
    const tokenLimits = quota.data.limits
      .filter((w) => w.type === "TOKENS_LIMIT")
      .sort((a, b) => (a.nextResetTime ?? 0) - (b.nextResetTime ?? 0));
    if (tokenLimits.length === 0) return null;

    const [sessionWindow, weeklyWindow] = tokenLimits;

    const sessionPercent = Math.round(sessionWindow.percentage);
    const sessionReset = sessionWindow.nextResetTime
      ? formatTimeUntil(sessionWindow.nextResetTime)
      : null;

    const sessionLabel = themed(theme, "muted", "session: ");
    const sessionTime = sessionReset
      ? themed(theme, "dim", ` (${sessionReset})`)
      : "";
    const separator = themed(theme, "dim", " | ");

    let status = `${sessionLabel}${formatUsedPercent(theme, sessionPercent)}${sessionTime}`;

    let weeklyPercent: number | undefined;
    if (weeklyWindow) {
      weeklyPercent = Math.round(weeklyWindow.percentage);
      const weeklyReset = weeklyWindow.nextResetTime
        ? formatTimeUntil(weeklyWindow.nextResetTime)
        : null;
      const weeklyLabel = themed(theme, "muted", "weekly: ");
      const weeklyTime = weeklyReset
        ? themed(theme, "dim", ` (${weeklyReset})`)
        : "";
      status += `${separator}${weeklyLabel}${formatUsedPercent(theme, weeklyPercent)}${weeklyTime}`;
    }

    return {
      statusText: status,
      notify: getQuotaNotification(
        Math.max(sessionPercent, weeklyPercent ?? 0),
        "Z.ai",
      ),
    };
  }

  // Very small helper so /model-quota output doesn't contain theme escape sequences.
  function stripAnsiLike(text: string): string {
    // pi theme strings are plain text, but we defensively strip common ANSI just in case.
    return text.replace(/\x1b\[[0-9;]*m/g, "");
  }

  async function readAuthData(): Promise<AuthConfig | null> {
    const now = Date.now();
    if (cachedAuthData && now - lastAuthFetched < 60_000) return cachedAuthData;
    if (authFetchInFlight) return authFetchInFlight;

    const promise = (async () => {
      try {
        const raw = await readFile(PI_AUTH_PATH, "utf8");
        const data = JSON.parse(raw);
        cachedAuthData = data;
        lastAuthFetched = Date.now();
        return data;
      } catch {
        cachedAuthData = null;
        lastAuthFetched = 0;
        return null;
      } finally {
        authFetchInFlight = null;
      }
    })();

    authFetchInFlight = promise;
    return promise;
  }

  async function fetchWithTimeout(
    url: string,
    options: RequestInit,
    timeoutMs: number = FETCH_TIMEOUT_MS,
  ): Promise<Response> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

    try {
      return await fetch(url, { ...options, signal: controller.signal });
    } finally {
      clearTimeout(timeoutId);
    }
  }

  function normalizeGitHubCopilotEnterpriseDomain(
    value: unknown,
  ): string | null {
    if (typeof value !== "string") return null;
    const trimmed = value.trim();
    if (!trimmed) return null;

    try {
      const url = trimmed.includes("://")
        ? new URL(trimmed)
        : new URL(`https://${trimmed}`);
      return url.hostname;
    } catch {
      return null;
    }
  }

  function getGitHubApiBaseUrl(domain: string): string {
    if (domain === "github.com") return "https://api.github.com";
    return `https://api.${domain}`;
  }

  async function fetchGitHubCopilotUser(): Promise<GitHubCopilotUserResponse | null> {
    // Cache for 60 seconds
    const now = Date.now();
    if (cachedGitHubCopilotUser && now - lastGitHubCopilotFetched < 60 * 1000) {
      return cachedGitHubCopilotUser;
    }

    try {
      const authData = await readAuthData();
      const copilotAuth = authData?.["github-copilot"];
      const refreshToken = copilotAuth?.refresh as string | undefined;
      if (!refreshToken) return null;

      const enterpriseDomain = normalizeGitHubCopilotEnterpriseDomain(
        copilotAuth?.enterpriseUrl,
      );
      const domain = enterpriseDomain || "github.com";
      const apiBaseUrl = getGitHubApiBaseUrl(domain);

      const response = await fetchWithTimeout(
        `${apiBaseUrl}/copilot_internal/user`,
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${refreshToken}`,
            Accept: "application/json",
            "User-Agent": "GitHubCopilotChat/0.35.0",
          },
        },
      );

      if (!response.ok) {
        logDebug("GitHub Copilot quota API error:", response.status);
        return null;
      }

      cachedGitHubCopilotUser =
        (await response.json()) as unknown as GitHubCopilotUserResponse;
      lastGitHubCopilotFetched = now;
      return cachedGitHubCopilotUser;
    } catch (error) {
      logDebug("Failed to fetch GitHub Copilot quota:", error);
      return null;
    }
  }

  async function readModelsData(): Promise<ModelsConfig | null> {
    const now = Date.now();
    if (modelsData && now - lastModelsFetched < 60_000) return modelsData;
    if (modelsFetchInFlight) return modelsFetchInFlight;

    const promise = (async () => {
      try {
        const raw = await readFile(PI_MODELS_PATH, "utf8");
        const data = JSON.parse(raw);
        modelsData = data;
        lastModelsFetched = Date.now();
        return data;
      } catch {
        modelsData = null;
        lastModelsFetched = 0;
        return null;
      } finally {
        modelsFetchInFlight = null;
      }
    })();

    modelsFetchInFlight = promise;
    return promise;
  }

  async function fetchZaiQuota(): Promise<ZaiQuotaLimit | null> {
    // Cache for 60 seconds
    const now = Date.now();
    if (cachedZaiQuota && now - lastZaiFetched < 60 * 1000) {
      return cachedZaiQuota;
    }

    try {
      const modelsData = await readModelsData();
      const zaiConfig = modelsData?.providers?.zai;
      if (!zaiConfig?.baseUrl) return null;

      // Resolve API key: if it looks like an env var name, read from environment
      let apiKey = zaiConfig.apiKey;
      if (
        typeof apiKey === "string" &&
        apiKey === apiKey.toUpperCase() &&
        /^[A-Z_]+$/.test(apiKey)
      ) {
        apiKey = process.env[apiKey] || null;
      }

      if (!apiKey) return null;

      // Construct the quota endpoint URL (base domain, not the model API path)
      const baseOrigin = new URL(zaiConfig.baseUrl).origin;
      const quotaUrl = `${baseOrigin}/api/monitor/usage/quota/limit`;

      const response = await fetchWithTimeout(quotaUrl, {
        method: "GET",
        headers: {
          Authorization: `Bearer ${apiKey}`,
          Accept: "application/json",
        },
      });

      if (!response.ok) {
        logDebug("Z.ai quota API error:", response.status);
        return null;
      }

      cachedZaiQuota = (await response.json()) as ZaiQuotaLimit;
      lastZaiFetched = now;
      return cachedZaiQuota;
    } catch (error) {
      logDebug("Failed to fetch Z.ai quota:", error);
      return null;
    }
  }
}
