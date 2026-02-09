/**
 * Coding Guardrails Extension
 *
 * Provides blocking guards for coding best practices and security.
 * Adapted for megalithic/dotfiles conventions:
 * - jj instead of git
 * - fd instead of find
 * - rg instead of grep
 * - nix instead of brew
 */

import type {
  ExtensionAPI,
  ToolCallEvent,
  AgentResponseEvent,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";

type Guard = (
  event: ToolCallEvent | AgentResponseEvent,
  ctx: ExtensionContext
) => { block: true; reason: string } | undefined;

// Helper to extract text from agent responses
function getResponseText(event: AgentResponseEvent): string {
  return event.response.content
    .filter((c) => c.type === "text")
    .map((c) => c.text)
    .join("\n");
}

// =============================================================================
// Guards
// =============================================================================

/**
 * Block corporate buzzwords and AI phrases
 */
const blockCorporateBuzzwords: GuardFn = (event) => {
  if (event.toolName !== "agent_response") return;

  const text = getResponseText(event as AgentResponseEvent);

  const buzzwordsPattern =
    /\b(comprehensive|robust|utilize|optimize|optimized|streamline|enhance|leverage|leverages|leveraging)\b/i;
  const aiPhrasesPattern = /\b(dive into|diving into|dives into)\b/i;

  if (buzzwordsPattern.test(text) || aiPhrasesPattern.test(text)) {
    return {
      block: true,
      reason:
        "Corporate buzzword or AI phrase detected.\n\n" +
        "**Banned words:** comprehensive, robust, utilize, optimize, streamline, enhance, leverage\n" +
        "**Banned AI phrases:** dive into / diving into\n\n" +
        "Use plain language instead.",
    };
  }
};

/**
 * Block git commands (should use jj)
 * Allows jj git subcommands except push
 */
const blockGitCommands: GuardFn = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;

  // Match standalone git command (not jj git)
  const gitPattern = /(^|[\s;&|])git\s+/;
  const jjGitPattern = /(^|[\s;&|])jj\s+git\s+/;

  if (gitPattern.test(cmd) && !jjGitPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "**git command blocked** - This repo uses Jujutsu (jj).\n\n" +
        "**Command mappings:**\n" +
        "- `git status` → `jj status`\n" +
        "- `git diff` → `jj diff`\n" +
        "- `git commit` → `jj describe`\n" +
        "- `git log` → `jj log`\n" +
        "- `git push` → `jj git push`\n" +
        "- `git pull` → `jj git fetch`",
    };
  }
};

/**
 * Block pushing (both git push and jj git push)
 */
const blockPush: GuardFn = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;

  const pushPattern = /(^|[\s;&|])(git\s+push|jj\s+git\s+push)/;

  if (pushPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "**push blocked** - Agent cannot push to remote.\n\n" +
        "Please review changes and push manually.",
    };
  }
};

/**
 * Block find command (should use fd)
 */
const blockFindCommand: GuardFn = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;

  // Match find command for file searching
  const findPattern = /(^|[\s;&|])find\s+/;

  if (findPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "**find command blocked** - Use `fd` instead.\n\n" +
        "**Examples:**\n" +
        "- `fd '\\.lua$'` - Find all .lua files\n" +
        "- `fd -e lua` - Same, using extension flag\n" +
        "- `fd -t f config` - Find files containing 'config'\n" +
        "- `fd -H '\\.env'` - Include hidden files",
    };
  }
};

/**
 * Block grep command (should use rg)
 */
const blockGrepCommand: GuardFn = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;

  // Match grep command
  const grepPattern = /(^|[\s;&|])grep\s+/;

  if (grepPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "**grep command blocked** - Use `rg` (ripgrep) instead.\n\n" +
        "**Examples:**\n" +
        "- `rg 'TODO'` - Search for TODO\n" +
        "- `rg -i 'error'` - Case-insensitive\n" +
        "- `rg 'import' -t lua` - Search only Lua files\n" +
        "- `rg -l 'TODO'` - List files with matches only",
    };
  }
};

/**
 * Block brew install (should use nix)
 */
const blockBrewInstall: GuardFn = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;

  const brewPattern = /(^|[\s;&|])brew\s+(install|cask|tap)/;

  if (brewPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "**brew install blocked** - This system uses Nix.\n\n" +
        "**Options:**\n" +
        "- `nix run nixpkgs#<package>` - Run once without installing\n" +
        "- `nix shell nixpkgs#<package>` - Temporary shell with package\n" +
        "- Add to `~/.dotfiles/home/programs/` for permanent install\n" +
        "- Use `just rebuild` after editing Nix configs",
    };
  }
};

/**
 * Block rm command (should use trash)
 */
const blockRmCommand: GuardFn = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;

  const rmPattern = /(^|[\s;&|])(sudo\s+)?(rm|rmdir)(\s|$)/;

  if (rmPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "**rm command blocked** - Use `trash` instead.\n\n" +
        "`rm` permanently deletes files. `trash` moves them to the system trash " +
        "where they can be recovered if needed.\n\n" +
        "**Examples:**\n" +
        "- `trash file.txt`\n" +
        "- `trash *.log`\n" +
        "- `trash -rf directory/`",
    };
  }
};

/**
 * Block npx/bunx usage
 */
const blockNpxBunx: GuardFn = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;
  const npxBunxPattern = /\b(npx|bunx)\s+/;

  if (npxBunxPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "**npx/bunx blocked** - Prefer package.json scripts or node_modules/.bin/\n\n" +
        "**Alternatives:**\n" +
        "1. Check for a package.json script\n" +
        "2. Use `./node_modules/.bin/<command>` directly\n" +
        "3. Add a script to package.json if it's a common operation",
    };
  }
};

/**
 * Block secret tools (pass, gpg exposure)
 */
const blockSecretTools: GuardFn = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;

  const cmdPosition = String.raw`(^|[|&;\`]|\$\()`;
  const secretPattern = new RegExp(
    cmdPosition + String.raw`\s*(pass|gpg)(\s|$)`
  );

  if (secretPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "**Secret management command blocked**\n\n" +
        "Running `pass` or `gpg` would expose secrets in the conversation context.\n\n" +
        "**Alternatives:**\n" +
        "- Run these commands manually in your terminal\n" +
        "- Use environment variables set outside pi\n" +
        "- Create wrapper scripts that use secrets without exposing them",
    };
  }
};

/**
 * Block title case headers in markdown
 */
/**
 * Block writes to nix-managed paths (should edit dotfiles source)
 */
const blockNixManagedWrites: GuardFn = (event) => {
  if (event.toolName !== "bash" && event.toolName !== "write" && event.toolName !== "edit") return;

  let targetPath = "";
  
  if (event.toolName === "bash") {
    const cmd = (event as ToolCallEvent).input.command;
    // Check for redirects or writes to managed paths
    const writePatterns = [
      />s*~\/bin\//,
      />s*\$HOME\/bin\//,
      />s*~\/\.config\//,
      />s*\$HOME\/\.config\//,
      />s*~\/\.hammerspoon\//,
      />s*\$HOME\/\.hammerspoon\//,
      />s*\/nix\/store\//,
    ];
    for (const pattern of writePatterns) {
      if (pattern.test(cmd)) {
        targetPath = cmd;
        break;
      }
    }
  } else {
    // write or edit tool
    targetPath = (event as ToolCallEvent).input.path || "";
  }

  if (!targetPath) return;

  // Expand ~ and $HOME for checking
  const expandedPath = targetPath
    .replace(/^~\//, process.env.HOME + "/")
    .replace(/^\$HOME\//, process.env.HOME + "/");

  // Map of managed paths to their dotfiles sources
  const managedPaths: Record<string, string> = {
    [process.env.HOME + "/bin/"]: "~/.dotfiles/bin/",
    [process.env.HOME + "/.config/"]: "~/.dotfiles/config/",
    [process.env.HOME + "/.hammerspoon/"]: "~/.dotfiles/config/hammerspoon/",
    [process.env.HOME + "/.pi/agent/"]: "~/.dotfiles/home/programs/ai/pi-coding-agent/",
  };

  for (const [managed, source] of Object.entries(managedPaths)) {
    if (expandedPath.includes(managed)) {
      const relativePath = expandedPath.split(managed)[1] || "";
      return {
        block: true,
        reason:
          `**Write to nix-managed path blocked**\n\n` +
          `\`${managed}\` is managed by nix/home-manager.\n\n` +
          `**Edit the source instead:**\n` +
          `\`${source}${relativePath}\`\n\n` +
          `Then run \`just rebuild\` if needed.`,
      };
    }
  }

  // Block writes to /nix/store
  if (expandedPath.includes("/nix/store/")) {
    return {
      block: true,
      reason:
        "**Write to /nix/store blocked** - Nix store is read-only.\n\n" +
        "Find the source file in `~/.dotfiles/` and edit there instead.",
    };
  }
};


const blockTitleCaseHeaders: GuardFn = (event) => {
  if (event.toolName !== "agent_response") return;

  const text = getResponseText(event as AgentResponseEvent);

  // Pattern matches headers with multiple title-cased words
  const titleCaseHeaderPattern = /^#+\s+(?:[A-Z][a-z]*\s+)+[A-Z][a-z]+/m;

  if (titleCaseHeaderPattern.test(text)) {
    return {
      block: true,
      reason:
        "**Title case header detected** - Use sentence case.\n\n" +
        "Examples:\n" +
        '- "Next Steps" → "Next steps"\n' +
        '- "Plan Overview" → "Plan overview"\n' +
        '- "API Key Setup" → "API key setup"',
    };
  }
};

// =============================================================================
// Extension entry point
// =============================================================================

const guards: Guard[] = [
  blockCorporateBuzzwords,
  blockGitCommands,
  blockPush,
  blockFindCommand,
  blockGrepCommand,
  blockBrewInstall,
  blockRmCommand,
  blockNpxBunx,
  blockSecretTools,
  blockNixManagedWrites,
  blockTitleCaseHeaders,
];

export default function (pi: ExtensionAPI) {
  const events = ["tool_call", "agent_response"] as const;

  for (const eventType of events) {
    pi.on(eventType, async (event, ctx) => {
      for (const guard of guards) {
        try {
          const result = guard(event, ctx);
          if (result?.block) {
            return result;
          }
        } catch (error) {
          console.error(`Error in guard:`, error);
        }
      }
    });
  }
}
