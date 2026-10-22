import { describe, expect, test } from "bun:test";

import { DEFAULT_MINS, GOLDEN_FRACTION, computeGolden, distribute, minAlong, scaleReference } from "../src/allocate";
import { type LayoutNode, parseLayout, serializeLayout } from "../src/layout";

const MINS = DEFAULT_MINS;

// Compact tmux 3.8 layout fixtures: p(pane, w, h, x, y), H/V(w, h, x, y, ...children).
const p = (id: number, w: number, h: number, x: number, y: number) => ({ t: "p", w, h, x, y, i: id, I: `%${id}` });
const split =
  (t: "h" | "v") =>
  (w: number, h: number, x: number, y: number, ...c: unknown[]) => ({ t, w, h, x, y, c });
const H = split("h");
const V = split("v");
const L = (root: unknown): LayoutNode => parseLayout(JSON.stringify({ V: 2, L: root }));
/** {1, [2, 3]} */
const NESTED = () => L(H(200, 50, 0, 0, p(1, 100, 50, 0, 0), V(99, 50, 101, 0, p(2, 99, 25, 101, 0), p(3, 99, 24, 101, 26))));

function leaf(node: LayoutNode, paneId: number): LayoutNode {
  if (node.type === "leaf") {
    if (node.paneId === paneId) return node;
    throw new Error(`pane ${paneId} not found`);
  }
  for (const c of node.children) {
    try {
      return leaf(c, paneId);
    } catch {
      // keep searching
    }
  }
  throw new Error(`pane ${paneId} not found`);
}

describe("distribute", () => {
  test("largest remainder is deterministic and exact", () => {
    const out = distribute(199, [
      { weight: 1, min: 4 },
      { weight: 1, min: 4 },
      { weight: 1, min: 4 },
    ]);
    expect(out).toEqual([67, 66, 66]);
  });

  test("honors minimums by redistribution", () => {
    const out = distribute(100, [
      { weight: 100, min: 4 },
      { weight: 1, min: 20 },
    ]);
    expect(out).toEqual([80, 20]);
  });

  test("returns null when minimums cannot fit", () => {
    expect(
      distribute(5, [
        { weight: 1, min: 4 },
        { weight: 1, min: 4 },
      ]),
    ).toBeNull();
  });

  test("total is always conserved", () => {
    for (let total = 20; total < 60; total++) {
      const out = distribute(total, [
        { weight: 3, min: 2 },
        { weight: 5, min: 2 },
        { weight: 7, min: 2 },
      ]);
      expect(out).not.toBeNull();
      expect(out!.reduce((a, b) => a + b, 0)).toBe(total);
    }
  });

  test("invalid totals and minimums fail without entering apportionment", () => {
    expect(distribute(1, [])).toBeNull();
    expect(distribute(0, [])).toEqual([]);
    expect(distribute(Number.NaN, [{ weight: 1, min: 0 }])).toBeNull();
    expect(distribute(10, [{ weight: 1, min: -1 }])).toBeNull();
    expect(distribute(10, [{ weight: 1, min: Number.POSITIVE_INFINITY }])).toBeNull();
  });

  test("zero, negative, and nonfinite weights cannot break conservation", () => {
    expect(
      distribute(10, [
        { weight: -1, min: 2 },
        { weight: 2, min: 2 },
      ]),
    ).toEqual([2, 8]);
    expect(
      distribute(10, [
        { weight: 0, min: 2 },
        { weight: 0, min: 2 },
      ]),
    ).toEqual([5, 5]);
    expect(
      distribute(10, [
        { weight: Number.POSITIVE_INFINITY, min: 2 },
        { weight: 1, min: 2 },
      ]),
    ).toEqual([2, 8]);
  });
});

describe("computeGolden", () => {
  const twoPane = L(H(200, 50, 0, 0, p(1, 100, 50, 0, 0), p(2, 99, 50, 101, 0)));

  test("focused pane gets exactly round(width/phi)", () => {
    const out = computeGolden(twoPane, 1, 200, 50, MINS)!;
    expect(leaf(out, 1).width).toBe(Math.round(200 * GOLDEN_FRACTION)); // 124
    expect(leaf(out, 2).width).toBe(200 - 1 - 124);
    expect(out.width).toBe(200);
  });

  test("focus switch gives the new pane the same exact target (grow and shrink)", () => {
    const first = computeGolden(twoPane, 1, 200, 50, MINS)!;
    const second = computeGolden(first, 2, 200, 50, MINS)!;
    expect(leaf(second, 2).width).toBe(124);
    expect(leaf(second, 1).width).toBe(75);
    // And back: identical to the first result (no drift from re-focusing).
    const third = computeGolden(second, 1, 200, 50, MINS)!;
    expect(serializeLayout(third)).toBe(serializeLayout(first));
  });

  test("vertical axis uses height target", () => {
    const vert = L(V(200, 50, 0, 0, p(1, 200, 25, 0, 0), p(2, 200, 24, 0, 26)));
    const out = computeGolden(vert, 2, 200, 50, MINS)!;
    expect(leaf(out, 2).height).toBe(Math.round(50 * GOLDEN_FRACTION)); // 31
    expect(leaf(out, 1).height).toBe(50 - 1 - 31);
  });

  test("nested layout: focused pane hits both axis targets", () => {
    // {1, [2, 3]} with focus on 3: width via outer h-split, height via inner v-split.
    const nested = NESTED();
    const out = computeGolden(nested, 3, 200, 50, MINS)!;
    expect(leaf(out, 3).width).toBe(124);
    expect(leaf(out, 3).height).toBe(31);
    expect(leaf(out, 2).height).toBe(50 - 1 - 31);
    expect(leaf(out, 1).width).toBe(200 - 1 - 124);
  });

  test("repeated-axis layout: three columns", () => {
    const three = L(H(200, 50, 0, 0, p(1, 66, 50, 0, 0), p(2, 66, 50, 67, 0), p(3, 66, 50, 134, 0)));
    const out = computeGolden(three, 2, 200, 50, MINS)!;
    expect(leaf(out, 2).width).toBe(124);
    // remaining 74 cells split evenly between the two unfocused columns
    expect(leaf(out, 1).width + leaf(out, 3).width).toBe(200 - 2 - 124);
    expect(Math.abs(leaf(out, 1).width - leaf(out, 3).width)).toBeLessThanOrEqual(1);
  });

  test("unfocused branches divide by leaf count and equalize nested groups", () => {
    // {1, [2, 3], 4} focused 1: the [2,3] branch (2 leaves) gets more width
    // than pane 4 (1 leaf)? No — width shares are per-column; leaf counts: 2 vs 1.
    const topo = L(
      H(
        200, 50, 0, 0,
        p(1, 66, 50, 0, 0),
        V(66, 50, 67, 0, p(2, 66, 25, 67, 0), p(3, 66, 24, 67, 26)),
        p(4, 66, 50, 134, 0),
      ),
    );
    const out = computeGolden(topo, 1, 200, 50, MINS)!;
    expect(leaf(out, 1).width).toBe(124);
    const rest = 200 - 2 - 124; // 74
    const branch = leaf(out, 2).width; // same column as 3
    expect(leaf(out, 2).width).toBe(leaf(out, 3).width);
    expect(branch + leaf(out, 4).width).toBe(rest);
    // leaf-count weighting: [2,3] has weight 2, pane 4 weight 1
    expect(branch).toBeGreaterThan(leaf(out, 4).width);
    // nested unfocused group is equalized vertically
    expect(Math.abs(leaf(out, 2).height - leaf(out, 3).height)).toBeLessThanOrEqual(1);
  });

  test("clamps to structural minimums when golden target cannot fit", () => {
    // 20 columns, 3 panes: golden target 12 for focus leaves 8 for two panes
    // (min 4 each + separators already consumed) — allocator must keep mins.
    const three = L(H(20, 50, 0, 0, p(1, 6, 50, 0, 0), p(2, 6, 50, 7, 0), p(3, 6, 50, 14, 0)));
    const out = computeGolden(three, 1, 20, 50, MINS)!;
    expect(leaf(out, 1).width).toBeGreaterThanOrEqual(MINS.width);
    expect(leaf(out, 2).width).toBeGreaterThanOrEqual(MINS.width);
    expect(leaf(out, 3).width).toBeGreaterThanOrEqual(MINS.width);
    const widths = [leaf(out, 1).width, leaf(out, 2).width, leaf(out, 3).width];
    expect(widths.reduce((a, b) => a + b, 0)).toBe(20 - 2);
    expect(leaf(out, 1).width).toBe(20 - 2 - MINS.width * 2); // largest legal size
  });

  test("returns null when even minimums cannot fit", () => {
    const three = L(H(10, 50, 0, 0, p(1, 2, 50, 0, 0), p(2, 2, 50, 3, 0), p(3, 4, 50, 6, 0)));
    expect(computeGolden(three, 1, 10, 50, MINS)).toBeNull();
  });

  test("floating panes take no tiled space and are kept unchanged", () => {
    const float = { t: "p", w: 100, h: 12, x: 4, y: 2, a: true, i: 9, z: 0, I: "%9" };
    const topo = L(H(200, 50, 0, 0, p(1, 100, 50, 0, 0), V(99, 50, 101, 0, p(2, 99, 25, 101, 0), float, p(3, 99, 24, 101, 26))));
    const out = computeGolden(topo, 3, 200, 50, MINS)!;
    expect(leaf(out, 3).width).toBe(124);
    expect(leaf(out, 3).height).toBe(31);
    expect(serializeLayout(out)).toContain(`,${JSON.stringify(float)},`);
    // A focused floating pane is not part of the tiled layout.
    expect(computeGolden(topo, 9, 200, 50, MINS)).toBeNull();
  });

  test("returns null for a missing focus pane", () => {
    expect(computeGolden(twoPane, 99, 200, 50, MINS)).toBeNull();
  });

  test("recomputation from exact ratios is stable across sizes (no drift)", () => {
    let topo: LayoutNode = twoPane;
    const at200 = serializeLayout(computeGolden(topo, 1, 200, 50, MINS)!);
    for (let i = 0; i < 100; i++) {
      const w = i % 2 === 0 ? 157 : 200;
      topo = computeGolden(topo, 1, w, 50, MINS)!;
    }
    expect(serializeLayout(computeGolden(topo, 1, 200, 50, MINS)!)).toBe(at200);
  });

  test("coordinates and separators are consistent", () => {
    const nested = NESTED();
    const out = computeGolden(nested, 3, 200, 50, MINS)!;
    const serialized = serializeLayout(out);
    // Round-trips through our own parser (structure is internally consistent).
    expect(serializeLayout(parseLayout(serialized))).toBe(serialized);
    const p2 = leaf(out, 2);
    const p3 = leaf(out, 3);
    expect(p3.y).toBe(p2.y + p2.height + 1);
    expect(p3.x).toBe(leaf(out, 1).width + 1);
  });
});

describe("minAlong", () => {
  test("derives from topology and separators", () => {
    const nested = NESTED();
    expect(minAlong(nested, "h", MINS)).toBe(MINS.width * 2 + 1);
    expect(minAlong(nested, "v", MINS)).toBe(MINS.height * 2 + 1);
  });
});

describe("scaleReference", () => {
  const ref = L(H(200, 50, 0, 0, p(1, 124, 50, 0, 0), V(75, 50, 125, 0, p(2, 75, 25, 125, 0), p(3, 75, 24, 125, 26))));
  /** the reference's topology at a new outer size */
  const at = (width: number, height: number): LayoutNode => ({ ...ref, width, height });

  test("pane fields and floating panes come from the current layout, not the reference", () => {
    const float = { t: "p", w: 50, h: 10, x: 3, y: 3, i: 9, z: 0, I: "%9" };
    const current = L(
      H(200, 50, 0, 0, { ...p(1, 100, 50, 0, 0), a: true }, V(99, 50, 101, 0, p(2, 99, 25, 101, 0), p(3, 99, 24, 101, 26), float)),
    );
    const out = serializeLayout(scaleReference(ref, current, MINS)!);
    expect(out).toContain('"w":124,"h":50,"x":0,"y":0,"i":1,"I":"%1","a":true');
    expect(out).toContain(JSON.stringify(float));
  });

  test("null when the split structure differs", () => {
    expect(scaleReference(ref, L(H(200, 50, 0, 0, p(1, 100, 50, 0, 0), p(2, 99, 50, 101, 0))), MINS)).toBeNull();
  });

  test("preserves proportions at a new size", () => {
    const out = scaleReference(ref, at(100, 50), MINS)!;
    expect(out.width).toBe(100);
    const w1 = leaf(out, 1).width;
    // 124/199 of 99 content cells ~ 61.7 -> 62
    expect(w1).toBe(62);
  });

  test("grow/shrink cycles return exactly to the reference", () => {
    const original = serializeLayout(scaleReference(ref, at(200, 50), MINS)!);
    for (let i = 0; i < 100; i++) {
      const w = i % 2 === 0 ? 143 : 200;
      const h = i % 3 === 0 ? 37 : 50;
      expect(scaleReference(ref, at(w, h), MINS)).not.toBeNull();
    }
    expect(serializeLayout(scaleReference(ref, at(200, 50), MINS)!)).toBe(original);
  });

  test("identity scale reproduces the reference geometry", () => {
    const out = scaleReference(ref, at(200, 50), MINS)!;
    expect(serializeLayout(out)).toBe(serializeLayout(ref));
  });

  test("null when minimums cannot fit", () => {
    expect(scaleReference(ref, at(7, 50), MINS)).toBeNull();
  });
});
