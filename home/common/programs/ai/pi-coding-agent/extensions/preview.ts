/**
 * Preview Extension
 *
 * Displays code, diffs, images, and other content in a tmux pane next to the agent.
 * Wraps the existing preview-ai bash script for content rendering.
 *
 * Usage:
 *   /preview [type] <content>
 *   /preview diff -r @
 *   /preview json '{"foo": "bar"}'
 *   /preview file /path/to/file.lua
 *   /preview markdown "# Hello"
 *   /preview image /path/to/image.png
 *
 * Types: json, markdown, diff, log, file, image, cmd, auto (default)
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

const VALID_TYPES = ["json", "markdown", "diff", "codediff", "log", "bead", "file", "image", "cmd", "text", "auto"];

type PreviewType = "json" | "markdown" | "diff" | "codediff" | "log" | "bead" | "file" | "image" | "cmd" | "text" | "auto";

interface PreviewOptions {
	type?: PreviewType;
	autoClose?: number;
	useDelta?: boolean;
}

/**
 * Check if we're running in a tmux session
 */
const isInTmux = (): boolean => {
	return Boolean(process.env.TMUX);
};

/**
 * Parse command arguments into options and content
 */
const parseArgs = (args: string[]): { options: PreviewOptions; content: string[] } => {
	const options: PreviewOptions = {
		type: "auto",
	};
	const content: string[] = [];
	let i = 0;

	while (i < args.length) {
		const arg = args[i];

		if (arg === "--auto-close-after" && i + 1 < args.length) {
			const seconds = parseInt(args[i + 1], 10);
			if (!isNaN(seconds) && seconds > 0) {
				options.autoClose = seconds;
			}
			i += 2;
			continue;
		}

		if (arg === "--delta") {
			options.useDelta = true;
			i += 1;
			continue;
		}

		if (arg === "-h" || arg === "--help") {
			options.type = undefined; // Signal to show help
			return { options, content: [] };
		}

		// Check if this looks like a type
		if (!options.type || options.type === "auto") {
			const maybeType = arg.toLowerCase();
			if (VALID_TYPES.includes(maybeType)) {
				options.type = maybeType as PreviewType;
				i += 1;
				continue;
			}
		}

		// Everything else is content
		content.push(arg);
		i += 1;
	}

	return { options, content };
};

/**
 * Build the preview-ai command
 */
const buildPreviewCommand = (options: PreviewOptions, content: string[]): string[] => {
	const cmd: string[] = ["preview-ai"];

	if (options.autoClose !== undefined) {
		cmd.push("--auto-close-after", options.autoClose.toString());
	}

	if (options.useDelta) {
		cmd.push("--delta");
	}

	if (options.type && options.type !== "auto") {
		cmd.push(options.type);
	}

	cmd.push(...content);

	return cmd;
};

/**
 * Show help text
 */
const showHelp = (ctx: ExtensionContext): void => {
	const helpText = `
**Preview Extension**

Display code, diffs, images, and other content in a tmux pane.

**Usage:**
  /preview [options] [type] <content>

**Options:**
  --auto-close-after <secs>  Auto-close pane after N seconds
  --delta                    Use delta for diff viewing (non-interactive)
  -h, --help                 Show this help

**Types:**
  json       JSON content (inline or file path)
  markdown   Markdown content (inline or file path)
  diff       jj diff arguments (e.g., "-r @") - uses codediff by default
  codediff   Explicit codediff.nvim mode (e.g., "HEAD~1 HEAD")
  log        jj log arguments (e.g., "-n 5")
  bead       Bead task ID - renders with glow
  file       File path to preview with bat
  image      Image file path (uses chafa/kitty)
  cmd        Shell command to execute (prefix with "cmd:")
  auto       Auto-detect type (default)

**Examples:**
  /preview json '{"foo": "bar"}'
  /preview diff -r @
  /preview --delta diff -r @
  /preview codediff HEAD~2 HEAD
  /preview file ~/.config/nvim/init.lua
  /preview markdown "# Hello World"
  /preview image /path/to/screenshot.png
  /preview --auto-close-after 5 diff

**Safety:**
  - Never renders in caller's pane
  - Only searches current session/window for existing previews
  - Reuses existing preview pane (kills and recreates)
`;

	ctx.ui.notify(helpText.trim(), "info");
};

/**
 * Execute preview-ai command
 */
const runPreview = async (pi: ExtensionAPI, ctx: ExtensionContext, options: PreviewOptions, content: string[]): Promise<void> => {
	// Validate tmux environment
	if (!isInTmux()) {
		ctx.ui.notify("Preview requires tmux. Run pi inside tmux to use this command.", "error");
		return;
	}

	// Validate content
	if (content.length === 0 && options.type !== "diff" && options.type !== "log") {
		ctx.ui.notify("No content provided. Use /preview --help for usage.", "error");
		return;
	}

	// Build command
	const cmd = buildPreviewCommand(options, content);

	// Execute preview-ai
	const result = await pi.exec(cmd[0], cmd.slice(1), {
		cwd: ctx.cwd,
		env: {
			...process.env,
			TMUX_PANE: process.env.TMUX_PANE || "",
		},
	});

	// Check for errors
	if (result.code !== 0) {
		const errorMsg = result.stderr?.trim() || result.stdout?.trim() || "preview-ai failed";
		ctx.ui.notify(`Preview error: ${errorMsg}`, "error");
		return;
	}

	// Success - preview pane should now be showing
	const typeLabel = options.type && options.type !== "auto" ? options.type : "content";
	ctx.ui.notify(`Preview opened: ${typeLabel}`, "info");
};

export default function (pi: ExtensionAPI): void {
	pi.registerCommand("preview", {
		description: "Display content in a tmux pane (code, diffs, images, etc.)",
		handler: async (args, ctx) => {
			const { options, content } = parseArgs(args);

			// Show help if requested
			if (options.type === undefined) {
				showHelp(ctx);
				return;
			}

			await runPreview(pi, ctx, options, content);
		},
	});

	// Register keyboard shortcut for quick diff preview
	pi.registerShortcut("ctrl+shift+p", {
		description: "Preview current diff in tmux pane",
		handler: async (ctx) => {
			if (!isInTmux()) {
				ctx.ui.notify("Preview requires tmux", "error");
				return;
			}

			await runPreview(pi, ctx, { type: "diff" }, []);
		},
	});
}
