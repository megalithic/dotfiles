import { describe, expect, test } from "bun:test";

import { layoutChecksum, leafPanes, parseLayout, samePaneSet, serializeLayout } from "./layout";

// Captured from a real tmux 3.7c server (200x50 window).
const REAL_LAYOUTS = [
  "21be,200x50,0,0{100x50,0,0,0,99x50,101,0[99x25,101,0,1,99x24,101,26,2]}",
  "423d,200x50,0,0{50x50,0,0,0,49x50,51,0,3,99x50,101,0[99x25,101,0,1,99x24,101,26,2]}",
  "d45b,200x50,0,0[200x24,0,0{99x24,0,0,0,100x24,100,0,3},200x25,0,25{99x25,0,25,1,100x25,100,25,2}]",
];

describe("parse/serialize round-trip", () => {
  for (const layout of REAL_LAYOUTS) {
    test(layout.slice(0, 24), () => {
      expect(serializeLayout(parseLayout(layout))).toBe(layout);
    });
  }

  test("single pane", () => {
    const layout = `${layoutChecksum("200x50,0,0,0")},200x50,0,0,0`;
    expect(serializeLayout(parseLayout(layout))).toBe(layout);
  });
});

describe("checksum", () => {
  test("matches tmux for captured layouts", () => {
    for (const layout of REAL_LAYOUTS) {
      expect(layoutChecksum(layout.slice(5))).toBe(layout.slice(0, 4));
    }
  });
});

describe("structure", () => {
  test("leaf panes in tree order", () => {
    expect(leafPanes(parseLayout(REAL_LAYOUTS[1]))).toEqual([0, 3, 1, 2]);
  });

  test("separator accounting", () => {
    const root = parseLayout(REAL_LAYOUTS[0]);
    if (root.type !== "split") throw new Error("expected split");
    const widths = root.children.map((c) => c.width);
    expect(widths.reduce((a, b) => a + b, 0) + root.children.length - 1).toBe(root.width);
  });

  test("samePaneSet ignores order", () => {
    const a = parseLayout(REAL_LAYOUTS[1]);
    const b = parseLayout(REAL_LAYOUTS[2]);
    expect(samePaneSet(a, b)).toBe(true);
    expect(samePaneSet(a, parseLayout(REAL_LAYOUTS[0]))).toBe(false);
  });
});

describe("malformed layouts", () => {
  const bad = ["", "abcd,", "200x50,0,0", "200x50,0,0{100x50,0,0,0", "200x50,0,0{}", "200x50,0,0,0trailing"];
  for (const layout of bad) {
    test(JSON.stringify(layout), () => {
      expect(() => parseLayout(layout)).toThrow();
    });
  }
});
