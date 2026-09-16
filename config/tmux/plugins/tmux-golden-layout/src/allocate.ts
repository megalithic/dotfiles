/**
 * Size allocation: exact golden-ratio focus resizing, declarative layouts,
 * and drift-free reference scaling.
 *
 * Every allocation starts from exact values (1/phi, declared ratios, or an
 * immutable reference layout) and current outer dimensions — never from a
 * previously rounded result — so repeated cycles cannot accumulate drift.
 */

import {
  type Axis,
  type LayoutNode,
  type Split,
  assignCoords,
  containsPane,
  leafCount,
} from "./layout";

/** Exact golden fraction 1/phi = (sqrt(5)-1)/2. */
export const GOLDEN_FRACTION = (Math.sqrt(5) - 1) / 2;

export interface Mins {
  /** minimum leaf width in cells */
  width: number;
  /** minimum leaf height in cells */
  height: number;
}

export const DEFAULT_MINS: Mins = { width: 4, height: 2 };

const axisSize = (axis: Axis, w: number, h: number): number => (axis === "h" ? w : h);

/**
 * Structural minimum of a subtree along an axis, derived from topology,
 * leaf minimums, and 1-cell separators.
 */
export function minAlong(node: LayoutNode, axis: Axis, mins: Mins): number {
  if (node.type === "leaf") return axis === "h" ? mins.width : mins.height;
  if (node.axis === axis) {
    return node.children.reduce((n, c) => n + minAlong(c, axis, mins), 0) + node.children.length - 1;
  }
  return Math.max(...node.children.map((c) => minAlong(c, axis, mins)));
}

/**
 * Size a subtree needs along an axis so the focused leaf reaches `target`,
 * with every other descendant at its structural minimum.
 */
function demandAlong(node: LayoutNode, axis: Axis, target: number, focusPane: number, mins: Mins): number {
  if (node.type === "leaf") {
    if (node.paneId !== focusPane) return minAlong(node, axis, mins);
    return Math.max(target, minAlong(node, axis, mins));
  }
  if (!containsPane(node, focusPane)) return minAlong(node, axis, mins);
  if (node.axis === axis) {
    return (
      node.children.reduce(
        (n, c) =>
          n + (containsPane(c, focusPane) ? demandAlong(c, axis, target, focusPane, mins) : minAlong(c, axis, mins)),
        0,
      ) +
      node.children.length -
      1
    );
  }
  return Math.max(
    ...node.children.map((c) =>
      containsPane(c, focusPane) ? demandAlong(c, axis, target, focusPane, mins) : minAlong(c, axis, mins),
    ),
  );
}

interface Share {
  weight: number;
  min: number;
}

/**
 * Deterministic largest-remainder apportionment without minimums.
 * Ties break by lower index.
 */
function largestRemainder(total: number, weights: number[]): number[] {
  const usable = weights.map((w) => (Number.isFinite(w) && w > 0 ? w : 0));
  const sumW = usable.reduce((a, b) => a + b, 0);
  const raw = usable.map((w) => (sumW > 0 ? (total * w) / sumW : total / usable.length));
  const floors = raw.map(Math.floor);
  let rest = total - floors.reduce((a, b) => a + b, 0);
  const order = raw
    .map((r, i) => ({ frac: r - Math.floor(r), i }))
    .sort((a, b) => b.frac - a.frac || a.i - b.i);
  const out = floors.slice();
  for (let k = 0; rest > 0; k = (k + 1) % order.length, rest--) out[order[k].i]++;
  return out;
}

/**
 * Split `total` cells among shares proportionally to weight, honoring
 * per-share minimums. Returns null when the minimums cannot fit.
 */
export function distribute(total: number, shares: Share[]): number[] | null {
  if (!Number.isSafeInteger(total) || total < 0) return null;
  if (shares.length === 0) return total === 0 ? [] : null;
  if (shares.some(({ min }) => !Number.isSafeInteger(min) || min < 0)) return null;
  const minSum = shares.reduce((a, s) => a + s.min, 0);
  if (total < minSum) return null;
  const result = new Array<number>(shares.length).fill(-1);
  let fixed = new Set<number>();
  for (;;) {
    const freeIdx = shares.map((_, i) => i).filter((i) => !fixed.has(i));
    if (freeIdx.length === 0) break;
    const fixedTotal = shares.reduce((a, s, i) => a + (fixed.has(i) ? s.min : 0), 0);
    const alloc = largestRemainder(total - fixedTotal, freeIdx.map((i) => shares[i].weight));
    const violations = freeIdx.filter((idx, k) => alloc[k] < shares[idx].min);
    if (violations.length === 0) {
      freeIdx.forEach((idx, k) => {
        result[idx] = alloc[k];
      });
      break;
    }
    fixed = new Set([...fixed, ...violations]);
  }
  for (let i = 0; i < shares.length; i++) if (fixed.has(i)) result[i] = shares[i].min;
  return result;
}

const clamp = (v: number, lo: number, hi: number): number => Math.min(Math.max(v, lo), hi);

function cloneTopology(node: LayoutNode): LayoutNode {
  if (node.type === "leaf") return { ...node };
  return { ...node, children: node.children.map(cloneTopology) };
}

/**
 * Recursively size `node` given its outer width/height, steering the focused
 * leaf toward the golden targets. Returns false when minimums cannot fit.
 */
function sizeNode(
  node: LayoutNode,
  width: number,
  height: number,
  focusPane: number,
  targetW: number,
  targetH: number,
  mins: Mins,
): boolean {
  node.width = width;
  node.height = height;
  if (node.type === "leaf") return true;

  const total = axisSize(node.axis, width, height);
  const content = total - (node.children.length - 1);
  const target = node.axis === "h" ? targetW : targetH;
  const childShares = node.children.map((c) => ({
    weight: leafCount(c),
    min: minAlong(c, node.axis, mins),
  }));

  let alloc: number[] | null = null;
  const fIdx = node.children.findIndex((c) => containsPane(c, focusPane));

  if (fIdx >= 0 && Number.isFinite(target)) {
    const otherMin = childShares.reduce((a, s, i) => (i === fIdx ? a : a + s.min), 0);
    const avail = content - otherMin;
    const fMin = childShares[fIdx].min;
    if (avail >= fMin) {
      const demand = demandAlong(node.children[fIdx], node.axis, target, focusPane, mins);
      const f = clamp(Math.round(demand), fMin, avail);
      const others = node.children
        .map((c, i) => ({ c, i }))
        .filter(({ i }) => i !== fIdx);
      const rest = distribute(
        content - f,
        others.map(({ i }) => childShares[i]),
      );
      if (rest) {
        alloc = new Array(node.children.length).fill(0);
        alloc[fIdx] = f;
        others.forEach(({ i }, k) => {
          alloc![i] = rest[k];
        });
      }
    }
  }

  if (!alloc) {
    // No focus in this subtree, or the golden target cannot fit: fall back to
    // best-effort leaf-count distribution with structural minimums.
    alloc = distribute(content, childShares);
    if (!alloc) return false;
  }

  for (let i = 0; i < node.children.length; i++) {
    const c = node.children[i];
    const cw = node.axis === "h" ? alloc[i] : width;
    const ch = node.axis === "h" ? height : alloc[i];
    const hasFocus = containsPane(c, focusPane);
    const ok = hasFocus
      ? sizeNode(c, cw, ch, focusPane, targetW, targetH, mins)
      : sizeNode(c, cw, ch, -1, Number.NaN, Number.NaN, mins);
    if (!ok) return false;
  }
  return true;
}

/**
 * Compute a golden-ratio layout: the focused pane targets exactly
 * width*1/phi and height*1/phi wherever the topology has siblings along that
 * axis; unfocused branches share the remainder by leaf count.
 *
 * Returns a new sized tree, or null when the pane is missing or the window
 * cannot fit all structural minimums.
 */
export function computeGolden(
  topology: LayoutNode,
  focusPane: number,
  width: number,
  height: number,
  mins: Mins = DEFAULT_MINS,
): LayoutNode | null {
  if (!containsPane(topology, focusPane)) return null;
  const root = cloneTopology(topology);
  const targetW = width * GOLDEN_FRACTION;
  const targetH = height * GOLDEN_FRACTION;
  if (!sizeNode(root, width, height, focusPane, targetW, targetH, mins)) return null;
  assignCoords(root, 0, 0);
  return root;
}

// ── Declarations ──

export interface DeclSplit {
  split: Axis;
  /** optional exact ratios, same length as children; defaults to equal */
  ratios?: number[];
  children: DeclNode[];
}

export interface DeclPane {
  /** tmux pane id, e.g. "%12" */
  pane: string;
}

export type DeclNode = DeclSplit | DeclPane;

export interface Declaration {
  root: DeclNode;
}

export function declPanes(node: DeclNode): string[] {
  if ("pane" in node) return [node.pane];
  return node.children.flatMap(declPanes);
}

export function validateDeclaration(decl: unknown): string | null {
  const walk = (node: unknown): string | null => {
    if (!node || typeof node !== "object" || Array.isArray(node)) return "node must be an object";
    if ("pane" in node) {
      if (typeof node.pane !== "string" || !/^%\d+$/.test(node.pane)) {
        return `invalid pane id: ${JSON.stringify(node.pane)}`;
      }
      return null;
    }
    if (!("split" in node) || (node.split !== "h" && node.split !== "v")) {
      return `invalid split axis: ${JSON.stringify("split" in node ? node.split : undefined)}`;
    }
    if (!("children" in node) || !Array.isArray(node.children) || node.children.length < 1) {
      return "split has no children";
    }
    if ("ratios" in node && node.ratios !== undefined) {
      if (!Array.isArray(node.ratios)) return "ratios must be an array";
      if (node.ratios.length !== node.children.length) return "ratios length != children length";
      if (node.ratios.some((r) => typeof r !== "number" || !Number.isFinite(r) || !(r > 0))) {
        return "ratios must be finite and positive";
      }
      const sum = node.ratios.reduce<number>((a, b) => a + b, 0);
      if (Math.abs(sum - 1) > 0.01) return `ratios must sum to 1 (got ${sum})`;
    }
    for (const c of node.children) {
      const err = walk(c);
      if (err) return err;
    }
    return null;
  };
  if (!decl || typeof decl !== "object" || Array.isArray(decl) || !("root" in decl)) {
    return "declaration must contain a root node";
  }
  const err = walk(decl.root);
  if (err) return err;
  const panes = declPanes(decl.root as DeclNode);
  if (new Set(panes).size !== panes.length) return "duplicate pane in declaration";
  return null;
}

function declToTopology(node: DeclNode): LayoutNode {
  if ("pane" in node) {
    return { type: "leaf", width: 0, height: 0, x: 0, y: 0, paneId: Number.parseInt(node.pane.slice(1), 10) };
  }
  return {
    type: "split",
    axis: node.split,
    width: 0,
    height: 0,
    x: 0,
    y: 0,
    children: node.children.map(declToTopology),
  };
}

function sizeDeclared(node: LayoutNode, decl: DeclNode, width: number, height: number, mins: Mins): boolean {
  node.width = width;
  node.height = height;
  if (node.type === "leaf") return true;
  const d = decl as DeclSplit;
  const content = axisSize(node.axis, width, height) - (node.children.length - 1);
  const alloc = distribute(
    content,
    node.children.map((c, i) => ({
      weight: d.ratios ? d.ratios[i] : leafCount(c),
      min: minAlong(c, node.axis, mins),
    })),
  );
  if (!alloc) return false;
  return node.children.every((c, i) => {
    const cw = node.axis === "h" ? alloc[i] : width;
    const ch = node.axis === "h" ? height : alloc[i];
    return sizeDeclared(c, d.children[i], cw, ch, mins);
  });
}

/**
 * Render a declaration to a sized layout tree at the given dimensions.
 * Ratios are reapplied from their exact declared values on every call.
 */
export function renderDeclaration(
  decl: Declaration,
  width: number,
  height: number,
  mins: Mins = DEFAULT_MINS,
): LayoutNode | null {
  const root = declToTopology(decl.root);
  if (!sizeDeclared(root, decl.root, width, height, mins)) return null;
  assignCoords(root, 0, 0);
  return root;
}

/** Build an even grid declaration (rows of columns) for a set of panes. */
export function gridDeclaration(panes: string[]): Declaration {
  if (panes.length === 1) return { root: { pane: panes[0] } };
  if (panes.length === 2) {
    return { root: { split: "v", children: [{ pane: panes[0] }, { pane: panes[1] }] } };
  }
  const cols = Math.ceil(Math.sqrt(panes.length));
  const rows: DeclNode[] = [];
  for (let i = 0; i < panes.length; i += cols) {
    const rowPanes = panes.slice(i, i + cols).map((p): DeclNode => ({ pane: p }));
    rows.push(rowPanes.length === 1 ? rowPanes[0] : { split: "h", children: rowPanes });
  }
  return { root: rows.length === 1 ? rows[0] : { split: "v", children: rows } };
}

// ── Reference scaling ──

function sizeScaled(node: LayoutNode, ref: LayoutNode, width: number, height: number, mins: Mins): boolean {
  node.width = width;
  node.height = height;
  if (node.type === "leaf") return true;
  const r = ref as Split;
  const content = axisSize(node.axis, width, height) - (node.children.length - 1);
  const alloc = distribute(
    content,
    node.children.map((c, i) => ({
      weight: axisSize(node.axis, r.children[i].width, r.children[i].height),
      min: minAlong(c, node.axis, mins),
    })),
  );
  if (!alloc) return false;
  return node.children.every((c, i) => {
    const cw = node.axis === "h" ? alloc[i] : width;
    const ch = node.axis === "h" ? height : alloc[i];
    return sizeScaled(c, r.children[i], cw, ch, mins);
  });
}

/**
 * Scale an immutable reference layout to new outer dimensions, preserving
 * its proportions. The reference is never mutated, so repeated grow/shrink
 * cycles that return to the original size reproduce the original layout.
 */
export function scaleReference(
  ref: LayoutNode,
  width: number,
  height: number,
  mins: Mins = DEFAULT_MINS,
): LayoutNode | null {
  const root = cloneTopology(ref);
  if (!sizeScaled(root, ref, width, height, mins)) return null;
  assignCoords(root, 0, 0);
  return root;
}
