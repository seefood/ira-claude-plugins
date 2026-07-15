---
name: test-before-install
description: >-
  Vet a third-party agent artifact (Claude Code skill, plugin, MCP server) or a
  local "enhancement" (settings/keybinding/hook change) from a remote or external
  source BEFORE installing it locally. Fetches the source read-only into quarantine,
  runs static + type-appropriate scanners in isolation, verifies findings by hand,
  and reports a verdict with the side effects to consent to. Use whenever asked to
  install / add / try / vet a skill or plugin from a git URL, marketplace,
  ".skill"/zip, or gist (e.g. "/plugin marketplace add ...", "install this skill",
  "is this repo safe to install", "add this MCP server"), and BEFORE running any
  installer or writing to ~/.claude, ~/.codex, ~/.gemini, or ~/.cursor.
---

# Test Before Install

Vet an untrusted agent artifact before it touches the local environment. The
guiding rule: **fetch and inspect in isolation; never install or execute the
source until the review clears and the user consents.**

## Golden rules

- **Never run the artifact or its installer first.** No `curl | bash`, no
  `postinstall`, no launching an MCP server to "see what it does" — until reviewed.
- **Work on a read-only copy in quarantine.** Leave the real `~/.claude`
  (and `~/.codex` / `~/.gemini` / `~/.cursor`) untouched until the end.
- **Scanners give leads, humans give verdicts.** A DO NOT INSTALL score is an
  input; confirm the actual runtime path by reading it.

## Workflow

### 1. Provenance
Confirm the source is what the user intends: exact org/user + repo name (guard
against typosquats/impersonation), repo age/reputation, and the exact ref to
install. Prefer a pinned tag/commit over a moving branch. See
[references/best-practices.md](references/best-practices.md).

### 2. Quarantine + triage
Fetch read-only and get a first-pass risk inventory (never executes the source):

```bash
scripts/quarantine.sh <git-url> [ref]     # or a local dir, or a .zip
```

This prints the quarantine path, a file inventory, the detected **artifact type**
(skill / plugin / MCP config / npm / python), executable files, and grep hits for
install-time hooks, pipe-to-shell, network egress, obfuscation, credential/agent-
config access, config mutation, and prompt-injection language.

### 3. Scan (layer tools by artifact type)
Run static scanners in isolation. See
[references/scanning-tools.md](references/scanning-tools.md) for exact commands.
Baseline:
- **AI skill/plugin** → `skillspector scan <path> --no-llm`
- **MCP server / installed surface** → `snyk-agent-scan` in a sandboxed
  `CLAUDE_CONFIG_DIR` (auto-decline server launches; never run an unvetted server)
- **Every source** → gitleaks (secrets) + semgrep (SAST); add SCA/trivy/kubesec
  when a dependency manifest, container, or k8s manifest is present.

If a scanner or the user wants deeper coverage, add more tools from that reference
before deciding — do not stop at one tool when the source is high-value or the
first pass is ambiguous.

### 4. Verify findings by hand
Open every flagged file at the cited line and classify each hit as true risk vs.
noise (test fixtures, license text, install docs, inherent-to-function quoting).
Read the primary executable(s), all install-time/hook code, and the full
SKILL.md / system prompt regardless of scanner output.
See [references/triage.md](references/triage.md) for the false-positive and
red-flag catalogs and how to reconcile disagreeing scanners.

### 5. Verdict + informed consent
Report, per artifact:
- **Verdict:** safe / safe-with-caveats / do-not-install, and the reasoning —
  including *why* scanners over- or under-flagged.
- **Side effects to consent to** even when safe: files/dirs written and where,
  local config changed, network access performed, extra API calls/cost, and
  permissions/tools expected.
- The exact ref reviewed and the quarantine path.

Present a short table when reviewing multiple sources at once.

### 6. Install only after approval
Install the **exact reviewed ref** into the real environment only after the user
approves. Then verify what landed matches quarantine. Delete the quarantine dir
(`rm -rf <QUARANTINE>`; ask before removing anything outside quarantine).
Re-run this whole process on any update — a safe version does not make the next
version safe.
