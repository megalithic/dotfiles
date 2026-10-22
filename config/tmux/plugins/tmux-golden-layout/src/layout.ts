/**
 * tmux 3.8 layout-string (JSON, version 2) parsing and serialization.
 *
 *   {"V":2,"L":{"t":"h","w":200,"h":50,"x":0,"y":0,"c":[
 *     {"t":"p","w":100,"h":50,"x":0,"y":0,"l":0,"i":0,"I":"%0"},
 *     {"t":"p","w":99,"h":50,"x":101,"y":0,"a":true,"i":1,"I":"%1"}]}}
 *
 * - t: "h" left-right split, "v" top-bottom split, "p" pane
 * - pane fields: a = active, l = last-pane order, i = pane index,
 *   z = floating z-order, I = pane id. select-layout applies a, l, i and z,
 *   so they are written back exactly as read.
 * - tiled siblings share a 1-cell border along the split axis:
 *   sum(children) + (n-1) == parent size.
 * - floating panes (those with "z") sit inside split cells but take no tiled
 *   space. They are set aside on parse and reinserted unchanged.
 */

export type Axis = "h" | "v"; // h = left-right, v = top-bottom

export interface Leaf {
  type: "leaf";
  width: number;
  height: number;
  x: number;
  y: number;
  /** numeric pane id (tmux `%12` -> 12) */
  paneId: number;
  /** non-geometry pane fields (a, l, i, I) in tmux's order */
  extra: Record<string, unknown>;
}

export interface Split {
  type: "split";
  axis: Axis;
  width: number;
  height: number;
  x: number;
  y: number;
  /** tiled children only */
  children: LayoutNode[];
  /** floating pane cells and their original index in tmux's child list */
  floating: { index: number; cell: unknown }[];
}

export type LayoutNode = Leaf | Split;

const GEOMETRY = new Set(["t", "w", "h", "x", "y", "c"]);

function parseCell(cell: unknown): LayoutNode {
  if (!cell || typeof cell !== "object" || Array.isArray(cell)) {
    throw new Error(`layout cell must be an object: ${JSON.stringify(cell)}`);
  }
  const c = cell as Record<string, unknown>;
  const [width, height, x, y] = [c.w, c.h, c.x, c.y];
  if (![width, height, x, y].every(Number.isSafeInteger)) {
    throw new Error(`layout cell has invalid geometry: ${JSON.stringify(cell)}`);
  }
  const geo = { width: width as number, height: height as number, x: x as number, y: y as number };
  if (c.t === "p") {
    const id = /^%(\d+)$/.exec(String(c.I));
    if (!id) throw new Error(`layout pane has invalid id: ${JSON.stringify(cell)}`);
    const extra = Object.fromEntries(Object.entries(c).filter(([k]) => !GEOMETRY.has(k)));
    return { type: "leaf", ...geo, paneId: Number(id[1]), extra };
  }
  if ((c.t !== "h" && c.t !== "v") || !Array.isArray(c.c) || c.c.length === 0) {
    throw new Error(`layout split is invalid: ${JSON.stringify(cell)}`);
  }
  const children: LayoutNode[] = [];
  const floating: Split["floating"] = [];
  c.c.forEach((child, index) => {
    const isFloating = child && typeof child === "object" && "z" in child;
    if (isFloating) floating.push({ index, cell: child });
    else children.push(parseCell(child));
  });
  return { type: "split", axis: c.t, ...geo, children, floating };
}

/** Parse a tmux 3.8 (`"V":2`) layout string. */
export function parseLayout(layout: string): LayoutNode {
  const doc = JSON.parse(layout) as { V?: unknown; L?: unknown } | null;
  if (doc?.V !== 2) throw new Error(`unsupported layout version: ${layout}`);
  return parseCell(doc.L);
}

function toCell(node: LayoutNode): unknown {
  const geo = { w: node.width, h: node.height, x: node.x, y: node.y };
  if (node.type === "leaf") return { t: "p", ...geo, ...node.extra };
  const c: unknown[] = node.children.map(toCell);
  for (const f of node.floating) c.splice(f.index, 0, f.cell); // ascending, so indexes line up
  return { t: node.axis, ...geo, c };
}

/** Serialize a layout tree to the string tmux's select-layout accepts (and #{window_layout} prints). */
export function serializeLayout(root: LayoutNode): string {
  return JSON.stringify({ V: 2, L: toCell(root) });
}

/**
 * Tiled geometry as a compact string, optionally with pane placement.
 * Ignores focus, last-pane order and floating panes, so it changes only when
 * tiled panes move or resize.
 */
export function shape(node: LayoutNode, withPanes = true): string {
  const head = `${node.width}x${node.height},${node.x},${node.y}`;
  if (node.type === "leaf") return withPanes ? `${head},${node.paneId}` : head;
  return `${head}${node.axis}(${node.children.map((c) => shape(c, withPanes)).join(",")})`;
}

/** Tiled leaf pane ids in tree order. */
export function leafPanes(node: LayoutNode): number[] {
  if (node.type === "leaf") return [node.paneId];
  return node.children.flatMap(leafPanes);
}

/** Count of tiled leaf panes under a node. */
export function leafCount(node: LayoutNode): number {
  if (node.type === "leaf") return 1;
  return node.children.reduce((n, c) => n + leafCount(c), 0);
}

/** True when the pane id is a tiled leaf somewhere under the node. */
export function containsPane(node: LayoutNode, paneId: number): boolean {
  if (node.type === "leaf") return node.paneId === paneId;
  return node.children.some((c) => containsPane(c, paneId));
}

/** Two layouts hold the same tiled pane set (order-insensitive). */
export function samePaneSet(a: LayoutNode, b: LayoutNode): boolean {
  const pa = leafPanes(a).sort((x, y) => x - y);
  const pb = leafPanes(b).sort((x, y) => x - y);
  return pa.length === pb.length && pa.every((v, i) => v === pb[i]);
}

/** Recompute tiled x/y coordinates for the whole tree from node sizes. */
export function assignCoords(node: LayoutNode, x: number, y: number): void {
  node.x = x;
  node.y = y;
  if (node.type === "leaf") return;
  let cursor = node.axis === "h" ? x : y;
  for (const child of node.children) {
    if (node.axis === "h") {
      child.height = node.height;
      assignCoords(child, cursor, y);
      cursor += child.width + 1;
    } else {
      child.width = node.width;
      assignCoords(child, x, cursor);
      cursor += child.height + 1;
    }
  }
}
