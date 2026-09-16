import { describe, expect, test } from "bun:test";

import {
  DEFAULT_MINS,
  GOLDEN_FRACTION,
  type Declaration,
  computeGolden,
  distribute,
  gridDeclaration,
  minAlong,
  renderDeclaration,
  scaleReference,
  validateDeclaration,
} from "./allocate";
import { type LayoutNode, leafPanes, parseLayout, serializeLayout } from "./layout";

const MINS = DEFAULT_MINS;

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
});

describe("computeGolden", () => {
  const twoPane = parseLayout("0000,200x50,0,0{100x50,0,0,1,99x50,101,0,2}");

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
    const vert = parseLayout("0000,200x50,0,0[200x25,0,0,1,200x24,0,26,2]");
    const out = computeGolden(vert, 2, 200, 50, MINS)!;
    expect(leaf(out, 2).height).toBe(Math.round(50 * GOLDEN_FRACTION)); // 31
    expect(leaf(out, 1).height).toBe(50 - 1 - 31);
  });

  test("nested layout: focused pane hits both axis targets", () => {
    // {1, [2, 3]} with focus on 3: width via outer h-split, height via inner v-split.
    const nested = parseLayout("0000,200x50,0,0{100x50,0,0,1,99x50,101,0[99x25,101,0,2,99x24,101,26,3]}");
    const out = computeGolden(nested, 3, 200, 50, MINS)!;
    expect(leaf(out, 3).width).toBe(124);
    expect(leaf(out, 3).height).toBe(31);
    expect(leaf(out, 2).height).toBe(50 - 1 - 31);
    expect(leaf(out, 1).width).toBe(200 - 1 - 124);
  });

  test("repeated-axis layout: three columns", () => {
    const three = parseLayout("0000,200x50,0,0{66x50,0,0,1,66x50,67,0,2,66x50,134,0,3}");
    const out = computeGolden(three, 2, 200, 50, MINS)!;
    expect(leaf(out, 2).width).toBe(124);
    // remaining 74 cells split evenly between the two unfocused columns
    expect(leaf(out, 1).width + leaf(out, 3).width).toBe(200 - 2 - 124);
    expect(Math.abs(leaf(out, 1).width - leaf(out, 3).width)).toBeLessThanOrEqual(1);
  });

  test("unfocused branches divide by leaf count and equalize nested groups", () => {
    // {1, [2, 3], 4} focused 1: the [2,3] branch (2 leaves) gets more width
    // than pane 4 (1 leaf)? No — width shares are per-column; leaf counts: 2 vs 1.
    const topo = parseLayout(
      "0000,200x50,0,0{66x50,0,0,1,66x50,67,0[66x25,67,0,2,66x24,67,26,3],66x50,134,0,4}",
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
    const three = parseLayout("0000,20x50,0,0{6x50,0,0,1,6x50,7,0,2,6x50,14,0,3}");
    const out = computeGolden(three, 1, 20, 50, MINS)!;
    expect(leaf(out, 1).width).toBeGreaterThanOrEqual(MINS.width);
    expect(leaf(out, 2).width).toBeGreaterThanOrEqual(MINS.width);
    expect(leaf(out, 3).width).toBeGreaterThanOrEqual(MINS.width);
    const widths = [leaf(out, 1).width, leaf(out, 2).width, leaf(out, 3).width];
    expect(widths.reduce((a, b) => a + b, 0)).toBe(20 - 2);
    expect(leaf(out, 1).width).toBe(20 - 2 - MINS.width * 2); // largest legal size
  });

  test("returns null when even minimums cannot fit", () => {
    const three = parseLayout("0000,10x50,0,0{2x50,0,0,1,2x50,3,0,2,4x50,6,0,3}");
    expect(computeGolden(three, 1, 10, 50, MINS)).toBeNull();
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
    const nested = parseLayout("0000,200x50,0,0{100x50,0,0,1,99x50,101,0[99x25,101,0,2,99x24,101,26,3]}");
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
    const nested = parseLayout("0000,200x50,0,0{100x50,0,0,1,99x50,101,0[99x25,101,0,2,99x24,101,26,3]}");
    expect(minAlong(nested, "h", MINS)).toBe(MINS.width * 2 + 1);
    expect(minAlong(nested, "v", MINS)).toBe(MINS.height * 2 + 1);
  });
});

describe("declarations", () => {
  const nvimPi: Declaration = {
    root: { split: "h", ratios: [0.65, 0.35], children: [{ pane: "%1" }, { pane: "%2" }] },
  };

  test("validate accepts known declarations", () => {
    expect(validateDeclaration(nvimPi)).toBeNull();
  });

  test("validate rejects bad ratios, panes, duplicates", () => {
    expect(
      validateDeclaration({
        root: { split: "h", ratios: [0.9, 0.9], children: [{ pane: "%1" }, { pane: "%2" }] },
      }),
    ).toMatch(/sum to 1/);
    expect(validateDeclaration({ root: { pane: "nope" } })).toMatch(/invalid pane/);
    expect(
      validateDeclaration({ root: { split: "h", children: [{ pane: "%1" }, { pane: "%1" }] } }),
    ).toMatch(/duplicate/);
    expect(
      validateDeclaration({ root: { split: "x" as never, children: [{ pane: "%1" }] } }),
    ).toMatch(/axis/);
  });

  test("renders exact 65/35 split", () => {
    const out = renderDeclaration(nvimPi, 200, 50, MINS)!;
    expect(leaf(out, 1).width).toBe(Math.round(0.65 * 199) === 129 ? 129 : leaf(out, 1).width);
    expect(leaf(out, 1).width + leaf(out, 2).width).toBe(199);
    // exact largest-remainder from 0.65: floor(129.35)=129
    expect(leaf(out, 1).width).toBe(129);
    expect(leaf(out, 2).width).toBe(70);
  });

  test("ratio preserved across outer resizes without drift", () => {
    const at200 = serializeLayout(renderDeclaration(nvimPi, 200, 50, MINS)!);
    for (const w of [150, 120, 300, 200]) {
      renderDeclaration(nvimPi, w, 50, MINS);
    }
    expect(serializeLayout(renderDeclaration(nvimPi, 200, 50, MINS)!)).toBe(at200);
  });

  test("pi + subagents 50/50 with nested grid", () => {
    const decl: Declaration = {
      root: {
        split: "h",
        ratios: [0.5, 0.5],
        children: [
          { pane: "%1" },
          { split: "v", children: [{ pane: "%2" }, { pane: "%3" }] },
        ],
      },
    };
    const out = renderDeclaration(decl, 201, 50, MINS)!;
    expect(leaf(out, 1).width).toBe(100);
    expect(leaf(out, 2).width).toBe(100);
    expect(leaf(out, 2).height + leaf(out, 3).height).toBe(49);
  });

  test("returns null when declaration cannot fit minimums", () => {
    expect(renderDeclaration(nvimPi, 6, 50, MINS)).toBeNull();
  });

  test("grid declaration shapes", () => {
    expect(gridDeclaration(["%1"])).toEqual({ root: { pane: "%1" } });
    expect(gridDeclaration(["%1", "%2"])).toEqual({
      root: { split: "v", children: [{ pane: "%1" }, { pane: "%2" }] },
    });
    const grid4 = gridDeclaration(["%1", "%2", "%3", "%4"]);
    expect(validateDeclaration(grid4)).toBeNull();
    const rendered = renderDeclaration(grid4, 200, 50, MINS)!;
    expect(leafPanes(rendered)).toEqual([1, 2, 3, 4]);
    // 2x2 grid: equal columns/rows within 1 cell
    expect(Math.abs(leaf(rendered, 1).width - leaf(rendered, 2).width)).toBeLessThanOrEqual(1);
    expect(Math.abs(leaf(rendered, 1).height - leaf(rendered, 3).height)).toBeLessThanOrEqual(1);
  });
});

describe("scaleReference", () => {
  const ref = parseLayout("0000,200x50,0,0{124x50,0,0,1,75x50,125,0[75x25,125,0,2,75x24,125,26,3]}");

  test("preserves proportions at a new size", () => {
    const out = scaleReference(ref, 100, 50, MINS)!;
    expect(out.width).toBe(100);
    const w1 = leaf(out, 1).width;
    // 124/199 of 99 content cells ~ 61.7 -> 62
    expect(w1).toBe(62);
  });

  test("grow/shrink cycles return exactly to the reference", () => {
    const original = serializeLayout(scaleReference(ref, 200, 50, MINS)!);
    for (let i = 0; i < 100; i++) {
      const w = i % 2 === 0 ? 143 : 200;
      const h = i % 3 === 0 ? 37 : 50;
      expect(scaleReference(ref, w, h, MINS)).not.toBeNull();
    }
    expect(serializeLayout(scaleReference(ref, 200, 50, MINS)!)).toBe(original);
  });

  test("identity scale reproduces the reference geometry", () => {
    const out = scaleReference(ref, 200, 50, MINS)!;
    expect(serializeLayout(out)).toBe(serializeLayout(ref));
  });

  test("null when minimums cannot fit", () => {
    expect(scaleReference(ref, 7, 50, MINS)).toBeNull();
  });
});
