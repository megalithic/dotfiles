/**
 * Nvim Review Extension
 *
 * Routes a review request to the paired Neovim editor service so it opens the
 * worktree-aware `:PiReview` UI in the connected Nvim instance.
 *
 * This is distinct from the existing `/review` pi-review-loop extension
 * (extensions/review.ts), which performs agent-driven checkout/snapshot
 * reviews. `/piview` never checks out branches or snapshots files; it only
 * asks the active paired Nvim to open its local review surface.
 *
 * Usage:
 *   /piview                  -> uncommitted
 *   /piview uncommitted
 *   /piview unpushed
 *   /piview branch
 *   /piview pr
 *   /piview ticket
 *   /piview worktrees
 *   /piview branch status     -> Neogit status only
 *   /piview branch range      -> Neogit + diff range against branch base
 *
 * Pairing safety: uses globalThis.pinvimEditorService, which targets only the
 * active paired Nvim. When no editor service is connected (bare Pi), `/piview`
 * spawns a review Nvim in a new tmux pane that adopts the worktree registry
 * identity and pairs back to this Pi (dot-zarv). It never scans manifests or
 * steals another Nvim pair.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const SCOPES = [
  "uncommitted",
  "unpushed",
  "branch",
  "pr",
  "ticket",
  "worktrees",
] as const;

type Scope = (typeof SCOPES)[number];

const DIFF_MODES = [
  "status",
  "worktree",
  "staged",
  "unstaged",
  "range",
] as const;

type DiffMode = (typeof DIFF_MODES)[number];

const SCOPE_DESCRIPTIONS: Record<Scope, string> = {
  uncommitted: "Working tree changes not yet committed",
  unpushed: "Commits on this branch not yet pushed",
  branch: "Full branch diff against its base",
  pr: "Open the PR review flow (Guh)",
  ticket: "Changes associated with the active ticket",
  worktrees: "Overview across all worktrees",
};

interface EditorServiceApi {
  query: (
    method: string,
    params: Record<string, unknown>,
  ) => Promise<EditorQueryResult>;
  status: () => {
    connected: boolean;
    stale: boolean;
    address: string | null;
  };
  spawnReviewNvim: (
    scope: string,
    worktreeCwd?: string,
    diffMode?: string,
  ) => {
    ok: boolean;
    socket?: string;
    worktree?: string;
    workspaceId?: string;
    pane?: string;
    error?: string;
  };
  focusReviewPane: (paneOverride?: string) => {
    ok: boolean;
    pane?: string;
    error?: string;
  };
}

interface EditorQueryResult {
  ok: boolean;
  result?: unknown;
  error?: string;
}

interface ReviewOpenResult {
  ok: boolean;
  ran?: boolean;
  metadata?: {
    scope: string;
    worktree?: string;
    branch?: string;
    upstream?: string;
    base?: string;
    pr?: {
      number?: number;
      url?: string;
      baseRefName?: string;
      headRefName?: string;
    } | null;
    ticket?: string | null;
    diff_mode?: string | null;
  } | null;
  error?: string;
}

function isScope(value: string): value is Scope {
  return (SCOPES as readonly string[]).includes(value);
}

function isDiffMode(value: string): value is DiffMode {
  return (DIFF_MODES as readonly string[]).includes(value);
}

export default function (pi: ExtensionAPI): void {
  pi.registerCommand("piview", {
    description:
      "Open worktree-aware :PiReview in the paired Neovim (uncommitted|unpushed|branch|pr|ticket|worktrees)",
    getArgumentCompletions: (prefix: string) => {
      const items = SCOPES.map((scope) => ({
        value: scope,
        label: scope,
        description: SCOPE_DESCRIPTIONS[scope],
      }));
      const filtered = items.filter((item) =>
        item.value.startsWith(prefix.trimStart()),
      );
      return filtered.length > 0 ? filtered : null;
    },
    handler: async (args, ctx: ExtensionContext) => {
      const parts = args?.trim().split(/\s+/).filter(Boolean) || [];
      const raw = parts[0] || "uncommitted";
      if (!isScope(raw)) {
        ctx.ui.notify(
          `piview: unknown scope '${raw}'. Valid: ${SCOPES.join(", ")}`,
          "error",
        );
        return;
      }
      const scope: Scope = raw;

      const diffMode = parts[1];
      if (diffMode && !isDiffMode(diffMode)) {
        ctx.ui.notify(
          `piview: unknown diff mode '${diffMode}'. Valid: ${DIFF_MODES.join(", ")}`,
          "error",
        );
        return;
      }

      const editorService = (
        globalThis as unknown as {
          pinvimEditorService?: EditorServiceApi;
        }
      ).pinvimEditorService;

      if (!editorService) {
        ctx.ui.notify(
          "piview: no paired Neovim editor service available (pinvim not active)",
          "error",
        );
        return;
      }

      const status = editorService.status();
      if (!status.connected || status.stale || !status.address) {
        // No paired Nvim editor service: spawn a review Nvim that pairs back
        // to this Pi (dot-zarv). The bare Pi adopts the worktree registry
        // identity so the incoming Nvim peer is accepted.
        const spawned = editorService.spawnReviewNvim(
          scope,
          undefined,
          diffMode,
        );
        if (!spawned.ok) {
          ctx.ui.notify(
            `piview: could not spawn review Nvim: ${spawned.error || "unknown"}`,
            "error",
          );
          return;
        }
        editorService.focusReviewPane(spawned.pane);
        ctx.ui.notify(
          `piview: spawned review Nvim (${scope}) in new pane; pairing to ${spawned.worktree}`,
          "info",
        );
        return;
      }

      const response = await editorService.query("review.open", {
        scope,
        diff_mode: diffMode,
      });

      if (!response.ok) {
        ctx.ui.notify(
          `piview: editor service rejected review.open: ${response.error || "unknown error"}`,
          "error",
        );
        return;
      }

      const result = response.result as ReviewOpenResult | undefined;
      if (!result?.ok) {
        ctx.ui.notify(
          `piview: review.open failed: ${result?.error || "unknown error"}`,
          "error",
        );
        return;
      }

      editorService.focusReviewPane();

      const meta = result.metadata;
      const summary = meta
        ? `piview: opened ${meta.scope} in Nvim` +
          (meta.diff_mode ? ` diff=${meta.diff_mode}` : "") +
          (meta.branch ? ` [${meta.branch}]` : "") +
          (meta.ticket ? ` ticket=${meta.ticket}` : "")
        : "piview: review opened in Nvim";
      ctx.ui.notify(summary, "info");
    },
  });
}
