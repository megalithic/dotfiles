/**
 * File Size Guard — blocks reading image files over 5MB
 *
 * Claude API has a 5MB limit for base64-encoded images.
 * This extension intercepts read tool calls and:
 * 1. Detects image files by extension
 * 2. Checks file size before allowing read
 * 3. Blocks with helpful message if over limit
 *
 * The guard suggests resizing the image before retrying.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";
import { statSync } from "fs";
import { resolve } from "path";

// 5MB in bytes (Claude API limit for base64 images)
const MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024;
const MAX_IMAGE_SIZE_MB = 5;

// Image extensions to check
const IMAGE_EXTENSIONS = new Set([
  ".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".tiff", ".tif", ".ico", ".svg"
]);

function isImageFile(path: string): boolean {
  const ext = path.toLowerCase().match(/\.[^.]+$/)?.[0] || "";
  return IMAGE_EXTENSIONS.has(ext);
}

function getFileSizeBytes(absolutePath: string): number | null {
  try {
    const stats = statSync(absolutePath);
    return stats.size;
  } catch {
    return null;
  }
}

function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} bytes`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    // Only intercept read tool
    if (!isToolCallEventType("read", event)) return;

    const { path } = event.input;
    if (!path) return;

    // Only check image files
    if (!isImageFile(path)) return;

    // Resolve to absolute path
    const absolutePath = resolve(ctx.cwd, path);

    // Check file size
    const sizeBytes = getFileSizeBytes(absolutePath);
    if (sizeBytes === null) return; // Let read tool handle missing files

    if (sizeBytes > MAX_IMAGE_SIZE_BYTES) {
      const sizeFormatted = formatSize(sizeBytes);
      return {
        block: true,
        reason: `🛑 **Image too large** — ${sizeFormatted} exceeds ${MAX_IMAGE_SIZE_MB}MB API limit.

**To view this image, resize it first:**
\`\`\`bash
# Resize to 25% (usually sufficient)
magick "${path}" -resize 25% "${path.replace(/(\.[^.]+)$/, "-preview$1")}"

# Or reduce quality for JPEG
magick "${path}" -quality 60 "${path.replace(/(\.[^.]+)$/, "-preview.jpg")}"
\`\`\`

Then read the preview file instead.`,
      };
    }
  });
}
