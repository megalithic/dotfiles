# Strive repos

These rules apply to every repo under `~/code/work/strive/` (provider_portal and the other work repos), for every agent.

## Commits and pull requests never name the agent harness

- Commit messages, branch names, PR titles, PR descriptions and PR comments never mention Ultimate, Pi, Claude or any other agent or harness, agent or conversation numbers (`#18082`), or where the work was discussed ("screenshots in the Ultimate thread"). Write them as the engineer who did the work.
- Git already switches off Ultimate's `Ultimate-Conversation` trailer in these repos, and a pre-push check refuses any commit whose message contains the word "ultimate" (`~/.config/git/config.strive`). When it refuses, reword those commits and push again; never bypass it with `--no-verify`.
- Before `gh pr create` or `gh pr edit`, read the title and body once more for harness mentions.

## Screenshots go inline in the PR description

Show visual changes with screenshots in the PR description, attached with GitHub CLI's `--attach` (gh 2.99+). Never commit images to the repo or the PR branch, and never upload them to a public host (gists, buckets, image hosts).

- Reference each image by its local path in the body file, then attach the same file: gh uploads it to GitHub's private attachment storage, visible only to people with access to the repo, and rewrites the path to the uploaded URL.

  ```bash
  # body.md: ![The changed screen](./screenshot.png)
  gh pr create --base main --title "feat(onboarding): …" --body-file body.md --attach ./screenshot.png
  gh pr edit 123 --body-file body.md --attach ./screenshot.png   # an existing PR
  ```

- Alt text says what the image shows. Attachments the body doesn't reference are appended at the end.
- Screenshots come from dev data only: no PHI, real patient or provider records, or secrets on screen.

## Auth changes get Cloudflare's security audit before the PR opens

When a change touches authentication or authorization (login, sessions, tokens, MFA, OAuth, impersonation, roles, permissions or capabilities, API or webhook auth, password or credential handling), run a security review of its full commit range with Cloudflare's security-audit skill before opening the PR, and fix what it finds.

- Pi: load the `security-audit` skill.
- Ultimate: the skill lives in `~/.pi/agent/git/github.com/cloudflare/security-audit-skill/skills/security-audit/`. Read its `SKILL.md`, `ATTACK-CLASSES.md` and `WEB-PROTOCOL-AND-AUTH.md`, and apply its guidance mode (not the full audit workflow) to the `base..head` diff, through a reviewer you start with that range. In a repo whose review team has a `reviewer-security`, the review already does this.
- Say in the PR description that the security review ran and what it found, without naming the agent that ran it.
