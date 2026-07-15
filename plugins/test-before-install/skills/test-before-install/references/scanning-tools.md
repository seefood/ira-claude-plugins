# Scanning tools, by artifact type

Layer scanners on top of the `quarantine.sh` triage. Run static analysis first;
run anything dynamic ONLY inside the isolation described below. Match tools to
what the artifact actually is (from the "ARTIFACT TYPE" section of the triage).

Only the two AI-artifact scanners below have flags verified in-repo. For the
rest, invoke the corresponding installed skill rather than guessing CLI flags.

## AI agent skills / plugins (pre-install)

### skillspector — purpose-built pre-install repo scanner
Accepts a git URL, local dir, `.zip`, or `.md` directly.

```bash
skillspector scan <path|git-url> --no-llm -f terminal     # static + YARA, no API key
skillspector scan <path> -f json -o report.json           # machine-readable
skillspector scan <collection>/ --recursive               # each subdir with a SKILL.md
```

- `--no-llm` = static + YARA only (no credentials needed). The LLM pass is more
  accurate; enable it by setting a provider (`SKILLSPECTOR_PROVIDER` +
  e.g. `ANTHROPIC_API_KEY`) when available.
- Output includes a Risk Score + a DO NOT INSTALL / SAFE recommendation.
- Known over-flagging: adversarial strings in `evals/`/test fixtures, license
  boilerplate, and documented install steps. Verify every HIGH by hand
  (see triage.md) — the recommendation is an input to the decision, not the decision.

## MCP servers / installed-agent surface

### snyk-agent-scan — whole-machine MCP/skill scanner
Scans MCP config files and skills in well-known install locations. It is NOT a
per-repo tool, so isolate it to avoid scanning (or launching) your real config.

Isolate a candidate skill into a throwaway config dir, then scan only that:

```bash
SANDBOX="$(mktemp -d)"; mkdir -p "$SANDBOX/skills"
rsync -a --exclude .git <quarantined-skill>/ "$SANDBOX/skills/<name>/"
CLAUDE_CONFIG_DIR="$SANDBOX" snyk-agent-scan scan --no-bootstrap --skills < /dev/null
```

- `CLAUDE_CONFIG_DIR` relocates the Claude Code base it reads (own-home scans only).
- `< /dev/null` auto-declines the interactive "launch this stdio MCP server?"
  prompts — NEVER let it launch an unvetted server. `--no-bootstrap` skips the
  startup call to Snyk's control server.
- `--dangerously-run-mcp-servers` actually executes servers to inspect their
  tools. Only use it inside a container/VM, never for an untrusted source.
- `--json` emits a discovery inventory with taint flags (`is_public_sink`,
  `destructive`, `untrusted_content`, `private_data`); the human-readable
  W-code verdicts render to the terminal.

For MCP tool-description poisoning specifically, invoke the
`auditing-mcp-servers-for-tool-poisoning` skill.

## Generic code / supply-chain scanners (invoke the matching installed skill)

| Concern | Installed skill |
|---|---|
| Hardcoded secrets in the repo/history | `implementing-secret-scanning-with-gitleaks` |
| Source-level bug/RCE patterns (SAST) | `implementing-semgrep-for-custom-sast-rules` |
| Dependency CVEs (npm/pip/etc.) | `performing-sca-dependency-scanning-with-snyk` |
| Bundled container images | `scanning-docker-images-with-trivy` |
| Bundled k8s manifests | `scanning-kubernetes-manifests-with-kubesec` |
| Injection via untrusted content the skill ingests | `detecting-indirect-prompt-injection` |

Run gitleaks + semgrep on essentially every source before install; add SCA when
a dependency manifest is present, and trivy/kubesec when containers/manifests are.

## What no scanner reliably catches — read these by hand

- The primary executable(s) and any file the triage marked `+x`.
- Install-time / auto-run code: `package.json` `postinstall`, plugin/`hooks/`
  entries, `SessionStart`/`PreToolUse`/`Stop` hooks, `settings.json` mutations.
- The full SKILL.md/system-prompt text — for instructions to exfiltrate, persist
  state, escalate scope, or read credentials/agent config.
