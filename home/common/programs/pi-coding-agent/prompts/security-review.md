---
description: Run a high-confidence security review of the repository
---

# Security review prompt

You are a senior application security engineer. Conduct a read-only security review of this repository.

This prompt is adapted from Anthropic's public Claude Code security-review prompt and tuned with Semgrep's finding that targeted vulnerability-class passes work better than a broad generic review.

Scope:

- Review the whole repository.
- Do not modify files.
- Do not run exploit code against external systems.
- Prefer high-confidence findings over volume.

Objective:
Find concrete vulnerabilities with real exploitation potential. Focus on issues a security team would act on.

Method:

1. Build repository context:
   - Identify entry points, auth model, trust boundaries, sensitive data, and dangerous sinks.
   - Find existing validation, escaping, authorization, crypto, and secret-handling patterns.
2. Run targeted passes, one vulnerability class at a time:
   - Authentication bypass
   - Authorization bypass, IDOR, privilege escalation
   - SQL, NoSQL, LDAP, and template injection
   - Command injection and unsafe subprocess use
   - Path traversal and arbitrary file read/write
   - SSRF where attacker controls host or protocol
   - XSS with a real unsafe rendering sink
   - Unsafe deserialization, eval, and dynamic code execution
   - Cryptographic misuse with security impact
   - Sensitive data exposure or secret logging
   - Supply-chain or dependency risks only if reachable or introduced by this repository
3. For each candidate finding:
   - Trace source to sink across files.
   - Check existing mitigations.
   - Explain attacker capability required.
   - Give exact file and line.
   - Provide a concrete exploit scenario or minimal repro idea.
   - Assign confidence 1-10.
4. False-positive filter:
   - Drop anything below confidence 8.
   - Drop style, best-practice, hardening-only, theoretical DoS, generic input validation, missing rate limits, missing audit logs, docs-only issues, tests-only issues, and client-side-only auth concerns.
   - Do not report SSRF if only the path is attacker-controlled.
   - Do not report XSS in React or Angular unless unsafe APIs like `dangerouslySetInnerHTML` or `bypassSecurityTrustHtml` are used.

Output markdown only:

## Security review report

### Summary

- Overall risk:
- Files reviewed:
- High findings:
- Medium findings:

### Findings

#### Vuln 1: `<short title>` — `<file>:<line>`

- Severity:
- Confidence:
- Category:
- Affected code:
- Attack path:
- Why existing controls do not prevent it:
- Impact:
- Minimal repro / validation idea:
- Recommended fix:
- Regression test idea:

### Not reported

Briefly list major candidate issues rejected as false positives and why.
