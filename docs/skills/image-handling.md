---
name: image-handling
description: Image handling for Claude API constraints (5MB max, 8000px max dimension). Use when working with images, screenshots, or MCP browser tools.
tools: Bash
---

# Image Handling for Claude API

## Overview

**CRITICAL**: All images must fit within Anthropic's API constraints:
- **Max file size**: 5MB
- **Max dimension**: 8000px (width or height)

Images exceeding these limits will cause API errors.

## The resize-image Script

Location: `~/bin/resize-image`

### Quick Reference

```bash
resize-image --info <image>     # Show dimensions and size
resize-image --check <image>    # Quick check: "needs-resize" or "ok"
resize-image <image>            # Resize if needed (creates <name>-resized.<ext>)
resize-image <image> <output>   # Resize to specific output path
resize-image --quality 70 <image>  # Lower quality for more compression
```

### Standard Workflow

**Always check before processing:**

```bash
# 1. Check if resize is needed
resize-image --check /path/to/image.png

# 2. If output is "needs-resize", resize it
resize-image /path/to/image.png

# 3. Use the resized version
# Original: /path/to/image.png
# Resized:  /path/to/image-resized.png
```

### Flags

| Flag | Purpose |
|------|---------|
| `--info` | Show dimensions, file size, and whether it exceeds limits |
| `--check` | Quick check, outputs "ok" or "needs-resize" |
| `--quality N` | JPEG/WebP quality 1-100 (default: 85) |
| `--max-dimension N` | Override max dimension (default: 8000) |
| `--max-size N` | Override max file size in bytes (default: 5MB) |

## MCP Browser Screenshots

### Chrome DevTools MCP

When using `chrome-devtools` MCP for screenshots:

```typescript
// AVOID: Full-page screenshots of long pages
chrome-devtools_take_screenshot({ fullPage: true })  // May exceed limits!

// PREFER: Viewport-only screenshots
chrome-devtools_take_screenshot()  // Just visible area

// PREFER: Element screenshots for specific content
chrome-devtools_take_screenshot({ uid: "element-id" })

// SAFE: Save to file and resize before reading
chrome-devtools_take_screenshot({ filePath: "/tmp/screenshot.png" })
// Then: resize-image --check /tmp/screenshot.png
```

### Playwright MCP

Same principles apply:

```typescript
// AVOID
mcp__playwright__screenshot({ fullPage: true })

// PREFER
mcp__playwright__screenshot()  // Viewport only
mcp__playwright__screenshot({ element: "selector" })
```

### Post-Screenshot Workflow

When saving screenshots to disk via MCP:

```bash
# 1. Take screenshot to file
# (via MCP tool with filePath parameter)

# 2. Check if resize needed
resize-image --check /tmp/screenshot.png

# 3. If "needs-resize", resize before reading
resize-image /tmp/screenshot.png

# 4. Read the resized version
# /tmp/screenshot-resized.png
```

## Image Types and Compression

### Supported Formats

The resize-image script handles:
- PNG (lossless, larger files)
- JPEG (lossy, smaller files)
- WebP (lossy/lossless, smallest files)
- GIF (limited support)

### Compression Tips

```bash
# For screenshots with text (keep quality high)
resize-image --quality 90 screenshot.png

# For photos (can use lower quality)
resize-image --quality 70 photo.jpg

# For very large images, combine dimension + quality reduction
resize-image --quality 60 --max-dimension 4000 huge-image.png
```

## Common Scenarios

### User Provides Image Path

```bash
# 1. Check the image
resize-image --check /path/from/user.png

# 2. If "needs-resize"
resize-image /path/from/user.png
# Use: /path/from/user-resized.png

# 3. If "ok"
# Use original: /path/from/user.png
```

### Screenshot During Debugging

```bash
# 1. Take viewport screenshot (via MCP)
# Saved to: /tmp/debug-screenshot.png

# 2. Always check before processing
resize-image --check /tmp/debug-screenshot.png

# 3. Resize if needed, then read
```

### Multiple Images

```bash
# Check all images in a directory
for img in /path/to/images/*; do
  result=$(resize-image --check "$img")
  if [ "$result" = "needs-resize" ]; then
    resize-image "$img"
  fi
done
```

## Error Prevention

### Common Mistakes

```bash
# BAD: Reading image without checking size
cat /path/to/huge-image.png | base64  # May fail API limits

# GOOD: Check and resize first
resize-image --check /path/to/image.png
resize-image /path/to/image.png  # If needed
```

### API Error Signs

If you see errors like:
- "Image too large"
- "Payload size exceeds limit"
- "Invalid image dimensions"

**Solution**: Use `resize-image` before retrying.

## Technical Details

The script uses ImageMagick under the hood:
- Preserves aspect ratio when resizing
- Converts to sRGB colorspace for compatibility
- Strips metadata to reduce size
- Uses progressive encoding for JPEGs

### Manual Fallback (if script unavailable)

```bash
# Check dimensions
identify image.png

# Resize with ImageMagick
convert image.png -resize 8000x8000\> -quality 85 output.png
```
