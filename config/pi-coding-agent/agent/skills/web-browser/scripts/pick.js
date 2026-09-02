// Interactive element picker — inject via chrome_devtools_evaluate_script.
// Read this file and pass its contents as the `function` parameter.
// Returns: single element object, array (multi-select), or null (cancelled).
async () => {
  return await new Promise((resolve) => {
    const overlay = document.createElement("div");
    overlay.style.cssText =
      "position:fixed;top:0;left:0;width:100%;height:100%;z-index:2147483647;pointer-events:none";
    const highlight = document.createElement("div");
    highlight.style.cssText =
      "position:absolute;border:2px solid #3b82f6;background:rgba(59,130,246,0.1);transition:all 0.1s;pointer-events:none";
    overlay.appendChild(highlight);
    const banner = document.createElement("div");
    banner.style.cssText =
      "position:fixed;bottom:20px;left:50%;transform:translateX(-50%);background:#1f2937;color:white;padding:12px 24px;border-radius:8px;font:14px sans-serif;box-shadow:0 4px 12px rgba(0,0,0,0.3);pointer-events:auto;z-index:2147483647";
    const selections = [];
    const selectedElements = new Set();
    const updateBanner = () => {
      banner.textContent =
        "Click to select (" +
        selections.length +
        " selected). Cmd/Ctrl+Click = multi. Enter = done. ESC = cancel.";
    };
    updateBanner();
    document.body.append(banner, overlay);
    const cleanup = () => {
      document.removeEventListener("mousemove", onMove, true);
      document.removeEventListener("click", onClick, true);
      document.removeEventListener("keydown", onKey, true);
      overlay.remove();
      banner.remove();
      selectedElements.forEach((el) => (el.style.outline = ""));
    };
    const info = (el) => ({
      tag: el.tagName.toLowerCase(),
      id: el.id || null,
      class: el.className || null,
      text: (el.textContent || "").trim().slice(0, 200) || null,
      href: el.href || el.closest("a")?.href || null,
      html: el.outerHTML.slice(0, 500),
    });
    const onMove = (e) => {
      const el = document.elementFromPoint(e.clientX, e.clientY);
      if (!el || overlay.contains(el) || banner.contains(el)) return;
      const r = el.getBoundingClientRect();
      Object.assign(highlight.style, {
        top: r.top + "px",
        left: r.left + "px",
        width: r.width + "px",
        height: r.height + "px",
      });
    };
    const onClick = (e) => {
      if (banner.contains(e.target)) return;
      e.preventDefault();
      e.stopPropagation();
      const el = document.elementFromPoint(e.clientX, e.clientY);
      if (!el || overlay.contains(el) || banner.contains(el)) return;
      if (e.metaKey || e.ctrlKey) {
        if (!selectedElements.has(el)) {
          selectedElements.add(el);
          el.style.outline = "3px solid #10b981";
          selections.push(info(el));
          updateBanner();
        }
      } else {
        cleanup();
        resolve(selections.length > 0 ? selections : info(el));
      }
    };
    const onKey = (e) => {
      if (e.key === "Escape") {
        cleanup();
        resolve(null);
      } else if (e.key === "Enter" && selections.length > 0) {
        cleanup();
        resolve(selections);
      }
    };
    document.addEventListener("mousemove", onMove, true);
    document.addEventListener("click", onClick, true);
    document.addEventListener("keydown", onKey, true);
  });
};
