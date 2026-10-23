#!/usr/bin/env python3
"""Render a /code-review run into one HTML fragment for the pi artifact tool.

Usage: render.py <review-dir>

Reads from <review-dir>:
  meta.json           {"title","target","base","head","reviewers":{"A":..,"B":..,"C":..},"arbiter":..}
  arbiter.json        clusters array (see task-arbiter.md for the shape)
  arbiter-summary.md  arbiter's markdown summary (optional)
  engineer-summary.md paste-ready summary for the PR author (optional, shown first with raw markdown for copying)
  jev.json            {"C1":{"defect":0.9,"resolves":0.8,"fix_minimal":0.7,"severity":"..."}} (optional)
  report-cc.md, report-ponytail.md, report-rubric.md (optional, shown collapsed)
Writes <review-dir>/consensus.html
"""
import html
import json
import re
import sys
from pathlib import Path

base = Path(sys.argv[1]).expanduser().resolve()
meta = json.loads((base / "meta.json").read_text()) if (base / "meta.json").exists() else {}
clusters = json.loads((base / "arbiter.json").read_text())
jev = json.loads((base / "jev.json").read_text()) if (base / "jev.json").exists() else {}
summary_md = (base / "arbiter-summary.md").read_text() if (base / "arbiter-summary.md").exists() else ""
engineer_md = (base / "engineer-summary.md").read_text().strip() if (base / "engineer-summary.md").exists() else ""
reviewers = meta.get("reviewers", {})
labels = {
    "A": reviewers.get("A", "Claude Code /review recipe"),
    "B": reviewers.get("B", "ponytail-review skill"),
    "C": reviewers.get("C", "pi /review rubric"),
}
arbiter_label = meta.get("arbiter", "review-arbiter")
jev_model = meta.get("jev_model", "Jev")
reports = {"A": base / "report-cc.md", "B": base / "report-ponytail.md", "C": base / "report-rubric.md"}
e = html.escape


def bar(label, p):
    if p is None:
        return ""
    pct = round(p * 100)
    cls = "hi" if p >= 0.7 else ("mid" if p >= 0.4 else "lo")
    return (
        f'<div class="jev-row"><span class="jev-label">{e(label)}</span>'
        f'<span class="jev-bar"><span class="jev-fill {cls}" style="width:{pct}%"></span></span>'
        f'<span class="jev-val">{pct}%</span></div>'
    )


def jev_block(cid):
    j = jev.get(cid)
    if not j:
        return '<div class="jev"><span class="muted">Jev: not evaluated</span></div>'
    rows = [
        bar("real defect introduced by change", j.get("defect")),
        bar("answer resolves the question", j.get("resolves")),
        bar("fix is the smallest that works", j.get("fix_minimal")),
    ]
    sev = j.get("severity")
    sev_html = (
        f'<div class="jev-row"><span class="jev-label">severity (rubric)</span><span class="jev-choice">{e(str(sev))}</span></div>'
        if sev
        else ""
    )
    return f'<div class="jev"><div class="jev-title">{e(jev_model)} independent judgment</div>' + "".join(rows) + sev_html + "</div>"


def consensus_label(c):
    n = len(c.get("raised_by", []))
    kind = c.get("consensus", "")
    return "arbiter-only" if kind == "arbiter-only" else f"{n}/3 {kind}"


def item(c):
    cid = c["id"]
    sev = c.get("severity", "")
    verdict = c.get("verdict", "")
    loc = f'{c.get("file", "")}:{c.get("line", 0)}' if c.get("line") else c.get("file", "")
    positions = "".join(
        f'<li><span class="who">{e(r.get("reviewer", ""))} · {e(labels.get(r.get("reviewer", ""), ""))}</span>'
        f'<span class="fid">{e(r.get("finding", ""))}</span>'
        f'<span class="stated">{e(r.get("stated_severity", ""))}</span>'
        f'<div class="pos">{e(r.get("position", ""))}</div></li>'
        for r in c.get("raised_by", [])
    )
    disagreement = (c.get("disagreement") or "").strip()
    dis_html = f'<div class="disagree"><b>Disagreement:</b> {e(disagreement)}</div>' if disagreement else ""
    ctx = c.get("context", {})
    ans = c.get("answer", {})
    evidence = "".join(f"<li><code>{e(x)}</code></li>" for x in ans.get("evidence", []))
    return f"""
<article class="item sev-{e(sev)}" id="{e(cid)}">
  <header>
    <div class="badges">
      <span class="badge sev">{e(sev)}</span>
      <span class="badge verdict v-{e(verdict)}">{e(verdict)}</span>
      <span class="badge cons">{e(consensus_label(c))}</span>
      <span class="badge cat">{e(c.get("category", ""))}</span>
    </div>
    <h3>{e(cid)} — {e(c.get("title", ""))}</h3>
    <div class="loc"><code>{e(loc)}</code></div>
  </header>
  <div class="grid">
    <section class="context">
      <h4>Context</h4>
      <pre><code>{e(ctx.get("code", ""))}</code></pre>
      <p>{e(ctx.get("explanation", ""))}</p>
    </section>
    <section class="question">
      <h4>Question</h4>
      <p class="q">{e(c.get("question", ""))}</p>
      <h5>Reviewer positions</h5>
      <ul class="positions">{positions or '<li class="muted">none — arbiter-only</li>'}</ul>
      {dis_html}
    </section>
    <section class="answer">
      <h4>Answer <span class="muted">(arbiter · {e(arbiter_label)})</span></h4>
      <p>{e(ans.get("text", ""))}</p>
      {f'<ul class="evidence">{evidence}</ul>' if evidence else ''}
      <p class="fix"><b>Fix:</b> {e(ans.get("fix", ""))}</p>
      {jev_block(cid)}
    </section>
  </div>
</article>"""


def toc(cs):
    rows = []
    for c in cs:
        j = jev.get(c["id"]) or {}
        defect = f"{round((j.get('defect') or 0) * 100)}%" if j else ""
        rows.append(
            f'<tr><td><a href="#{e(c["id"])}">{e(c["id"])}</a></td>'
            f'<td><span class="badge sev sev-{e(c.get("severity", ""))}">{e(c.get("severity", ""))}</span></td>'
            f'<td><span class="badge verdict v-{e(c.get("verdict", ""))}">{e(c.get("verdict", ""))}</span></td>'
            f'<td>{e(consensus_label(c))}</td>'
            f'<td>{e(c.get("title", ""))}</td><td><code>{e(c.get("file", ""))}</code></td>'
            f'<td class="jevcell">{defect}</td></tr>'
        )
    return (
        '<table class="toc" id="toc"><thead><tr><th>#</th><th>Severity</th><th>Verdict</th><th>Consensus</th>'
        '<th>Title</th><th>File</th><th>Jev defect</th></tr></thead><tbody>' + "".join(rows) + "</tbody></table>"
    )


def raw_reports():
    out = []
    for key, p in reports.items():
        txt = p.read_text() if p.exists() else "(missing)"
        out.append(f'<details class="raw"><summary>Report {key} — {e(labels[key])}</summary><pre>{e(txt)}</pre></details>')
    return "".join(out)


def inline(s):
    s = e(s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", s)
    s = re.sub(r"\b(C\d+)\b", r'<a href="#\1">\1</a>', s)
    return s


def md_to_html(md):
    out = []
    for ln in md.splitlines():
        if ln.startswith("### "):
            out.append(f"<h4>{e(ln[4:])}</h4>")
        elif ln.startswith("## "):
            out.append(f"<h3>{e(ln[3:])}</h3>")
        elif ln.startswith("# "):
            out.append(f"<h2>{e(ln[2:])}</h2>")
        elif ln.startswith("- "):
            out.append(f"<li>{inline(ln[2:])}</li>")
        elif ln.strip() == "":
            out.append("")
        else:
            out.append(f"<p>{inline(ln)}</p>")
    s = "\n".join(out)
    return re.sub(r"((?:<li>.*?</li>\n?)+)", r"<ul>\1</ul>", s)


counts = {}
for c in clusters:
    counts[c.get("severity", "?")] = counts.get(c.get("severity", "?"), 0) + 1
count_html = " · ".join(f'<span class="badge sev sev-{e(k)}">{e(k)} {v}</span>' for k, v in counts.items())

css = """
<style>
.ccr { --blocker:#c62828; --should:#ef6c00; --cleanup:#1565c0; --dismiss:#6b6b6b; }
.ccr .badge { display:inline-block; padding:1px 8px; border-radius:10px; font-size:.75em; border:1px solid var(--border); margin-right:4px; color:var(--fg); background:var(--code-bg); }
.ccr .badge.sev { color:#fff; border-color:transparent; }
.ccr .sev-blocker .badge.sev, .ccr .badge.sev.sev-blocker { background:var(--blocker); }
.ccr .sev-should-fix .badge.sev, .ccr .badge.sev.sev-should-fix { background:var(--should); }
.ccr .sev-cleanup .badge.sev, .ccr .badge.sev.sev-cleanup { background:var(--cleanup); }
.ccr .sev-dismiss .badge.sev, .ccr .badge.sev.sev-dismiss { background:var(--dismiss); }
.ccr .badge.verdict.v-confirmed { border-color:var(--blocker); }
.ccr .badge.verdict.v-plausible { border-color:var(--should); }
.ccr .badge.verdict.v-refuted { border-color:var(--dismiss); opacity:.8; }
.ccr .item { border:1px solid var(--border); border-left:5px solid var(--border); border-radius:8px; padding:12px 16px; margin:18px 0; }
.ccr .item.sev-blocker { border-left-color:var(--blocker); }
.ccr .item.sev-should-fix { border-left-color:var(--should); }
.ccr .item.sev-cleanup { border-left-color:var(--cleanup); }
.ccr .item.sev-dismiss { border-left-color:var(--dismiss); opacity:.85; }
.ccr .item header h3 { margin:6px 0 2px; }
.ccr .loc { color:var(--muted); font-size:.9em; }
.ccr .grid { display:grid; grid-template-columns: 1.2fr 1fr 1.2fr; gap:14px; margin-top:10px; }
@media (max-width: 1100px) { .ccr .grid { grid-template-columns:1fr; } }
.ccr .grid section { background:var(--code-bg); border-radius:6px; padding:8px 12px; min-width:0; }
.ccr .grid h4 { margin:0 0 6px; font-size:.95em; text-transform:uppercase; letter-spacing:.04em; color:var(--muted); }
.ccr .grid h5 { margin:10px 0 4px; font-size:.85em; color:var(--muted); }
.ccr pre { white-space:pre-wrap; word-break:break-word; font-size:.8em; margin:0 0 8px; background:var(--bg); padding:8px; border-radius:4px; max-height:320px; overflow:auto; }
.ccr .q { font-weight:600; }
.ccr .positions { list-style:none; padding:0; margin:0; }
.ccr .positions li { margin:0 0 8px; padding:6px 8px; background:var(--bg); border-radius:4px; font-size:.9em; }
.ccr .who { font-weight:600; margin-right:6px; }
.ccr .fid, .ccr .stated { color:var(--muted); font-size:.85em; margin-right:6px; }
.ccr .pos { margin-top:2px; }
.ccr .disagree { margin-top:6px; padding:6px 8px; border-left:3px solid var(--should); background:var(--bg); font-size:.9em; }
.ccr .evidence { font-size:.85em; padding-left:18px; }
.ccr .fix { border-top:1px dashed var(--border); padding-top:6px; }
.ccr .jev { margin-top:8px; padding:6px 8px; background:var(--bg); border-radius:4px; font-size:.85em; }
.ccr .jev-title { color:var(--muted); margin-bottom:4px; }
.ccr .jev-row { display:flex; align-items:center; gap:8px; margin:2px 0; }
.ccr .jev-label { flex:0 0 220px; }
.ccr .jev-bar { flex:1; height:8px; background:var(--border); border-radius:4px; overflow:hidden; }
.ccr .jev-fill { display:block; height:100%; }
.ccr .jev-fill.hi { background:var(--blocker); } .ccr .jev-fill.mid { background:var(--should); } .ccr .jev-fill.lo { background:var(--dismiss); }
.ccr .jev-val { flex:0 0 40px; text-align:right; }
.ccr .jev-choice { font-weight:600; }
.ccr .toc { border-collapse:collapse; width:100%; font-size:.9em; }
.ccr .toc th, .ccr .toc td { border-bottom:1px solid var(--border); padding:4px 6px; text-align:left; vertical-align:top; }
.ccr .muted { color:var(--muted); font-weight:normal; }
.ccr details.raw { margin:10px 0; } .ccr details.raw pre { max-height:600px; }
.ccr .legend { font-size:.85em; color:var(--muted); margin:8px 0 16px; }
.ccr .engineer { border:1px solid var(--accent); border-radius:8px; padding:10px 16px; margin:12px 0 20px; }
.ccr .engineer h2 { margin-top:4px; }
.ccr .engineer details { margin-top:8px; }
.ccr .engineer pre { max-height:none; }
</style>
"""

title = meta.get("title") or "Consensus code review"
target = meta.get("target", "")
body = f"""
{css}
<div class="ccr">
<h1>{e(title)}</h1>
<p class="legend">Target: <code>{e(target)}</code> · base <code>{e(meta.get("base", ""))}</code> → head <code>{e(meta.get("head", ""))}</code>.
Three independent reviewers (A: {e(labels["A"])} · B: {e(labels["B"])} · C: {e(labels["C"])}) → arbiter {e(arbiter_label)} clustered and verified every finding against the checkout → {e(jev_model)} independently judged each item. Each card keeps context, question, reviewer positions and answer together.</p>
<p>{count_html} · {len(clusters)} items</p>
{f'<div class="engineer" id="engineer-summary"><h2>Summary for the PR author</h2>{md_to_html(engineer_md)}<details><summary>Raw markdown (copy for Slack / GitHub)</summary><pre>{e(engineer_md)}</pre></details></div>' if engineer_md else ''}
<div class="summary"><h2>Arbiter summary</h2>{md_to_html(summary_md)}</div>
<h2>Items</h2>
{toc(clusters)}
{"".join(item(c) for c in clusters)}
<h2>Raw reviewer reports</h2>
{raw_reports()}
</div>
"""
out = base / "consensus.html"
out.write_text(body)
print(f"wrote {out} ({len(body)} bytes, {len(clusters)} items)")
