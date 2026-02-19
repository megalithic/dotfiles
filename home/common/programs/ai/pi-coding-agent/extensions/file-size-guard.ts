/**
 * File Size Guard — blocks images over 5MB from reaching Claude API
 *
 * Claude API has a 5MB limit for base64-encoded images.
 * This extension guards against oversized images in two ways:
 *
 * 1. **Read tool** - intercepts `read` tool calls for image files
 * 2. **User input** - intercepts user messages with attached images
 *
 * Both are blocked with helpful resize suggestions.
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

// Type for image content in user messages
interface ImageContent {
  type: "image";
  source: {
    type: "base64" | "url";
    mediaType?: string;
    data?: string;
    url?: string;
  };
}

function isBase64Image(content: unknown): content is ImageContent {
  if (!content || typeof content !== "object") return false;
  const c = content as Record<string, unknown>;
  return c.type === "image" && c.source && typeof c.source === "object";
}

function getBase64SizeBytes(base64: string): number {
  // Base64 encoding is ~4/3 the size of binary data
  // Remove data URL prefix if present
  const data = base64.replace(/^data:[^;]+;base64,/, "");
  // Calculate actual binary size from base64 length
  const padding = (data.match(/=+$/) || [""])[0].length;
  return Math.floor((data.length * 3) / 4) - padding;
}

export default function (pi: ExtensionAPI) {
  // Guard 1: Intercept read tool for image files
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

  // Guard 2: Intercept user input with attached images
  pi.on("input", async (event, ctx) => {
    // Check if there are images in the input
    const images = event.images;
    if (!images || !Array.isArray(images) || images.length === 0) return;

    const oversizedImages: { index: number; size: string }[] = [];

    for (let i = 0; i < images.length; i++) {
      const img = images[i];
      if (!isBase64Image(img)) continue;

      // Check base64 source
      if (img.source.type === "base64" && img.source.data) {
        const sizeBytes = getBase64SizeBytes(img.source.data);
        if (sizeBytes > MAX_IMAGE_SIZE_BYTES) {
          oversizedImages.push({ index: i + 1, size: formatSize(sizeBytes) });
        }
      }
    }

    if (oversizedImages.length > 0) {
      const details = oversizedImages
        .map((o) => `• Image ${o.index}: ${o.size}`)
        .join("\n");

      ctx.ui.notify(
        `🛑 **Image(s) too large** — exceeds ${MAX_IMAGE_SIZE_MB}MB API limit:\n\n${details}\n\n**Resize before attaching:**\n\`magick input.png -resize 25% smaller.png\``,
        "error"
      );

      // Block the input
      return { action: "handled" as const };
    }
  });
}
