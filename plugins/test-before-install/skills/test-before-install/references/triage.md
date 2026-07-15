# Triaging findings: true risk vs. noise

Scanners and `quarantine.sh` flag patterns, not intent. A HIGH verdict is a lead
to investigate, not a verdict to relay. Open every flagged file at the cited line
and classify it. Never pass a raw scanner score to the user as the answer.

## Common FALSE POSITIVES (seen in practice)

- **Adversarial strings in test/eval fixtures.** `evals/`, `promptfooconfig.yaml`,
  `test/`, `fixtures/` deliberately contain payloads like "IGNORE PREVIOUS
  INSTRUCTIONS" to prove the artifact *resists* them. Confirm the string lives in
  a fixture and the harness asserts resistance — then it is a strength, not a risk.
- **License boilerplate.** MIT's "without restriction ... to deal in the Software"
  trips "scope creep" rules. Ignore hits whose only location is `LICENSE`.
- **Documented install steps.** A README/SKILL.md that says "add `VISUAL` to
  `settings.json`" is disclosing its behavior, not hiding an attack. It is still a
  real side effect to report for informed consent (see below) — just not malware.
- **Inherent-to-function quoting.** Any skill that analyzes or cites user-provided
  documents "could reproduce secrets if you paste secrets." That is a property of
  the task, not a defect. Flag it only as a usage caveat.
- **Placeholder example URLs.** `https://api.example.com`, `example.org`, `localhost`
  in a sample spec are not exfiltration endpoints.

## Genuine RED FLAGS — escalate / do not install without a clear explanation

- **Remote code execution on install/load:** `curl … | bash`, `iwr … | iex`,
  `eval`/`exec` of downloaded or decoded content, `postinstall` that fetches +
  runs code, plugin/`SessionStart` hooks running opaque commands.
- **Obfuscation:** base64/ROT13/`\xNN`/`fromCharCode`-encoded payloads that get
  decoded then executed. Legitimate skills have no reason to hide code.
- **Credential / key access:** reading `~/.ssh`, `~/.aws/credentials`, `.env`,
  `id_rsa`, browser stores, or scraping env vars for tokens — especially paired
  with network egress.
- **Exfiltration:** any network call whose payload includes file contents, env
  vars, conversation history, or tool output, to a non-obvious host.
- **Unexpected persistence:** cron/launchd/systemd, shell-rc edits, or writes into
  agent config dirs the artifact has no functional reason to touch. (Writing a
  documented state file into the CWD is usually fine.)
- **Config/keybinding hijack:** silently rebinding keys, changing `VISUAL`/`EDITOR`
  to a wrapper, or editing `settings.json` beyond what the docs state.
- **MCP tool poisoning:** tool/description text carrying hidden instructions to the
  agent (see `detecting-indirect-prompt-injection` / tool-poisoning skills).
- **Provenance mismatch:** the ref you'd install differs from what's advertised;
  a fork diverges from upstream in the executable/hook surface; typosquatted name.

## When scanners disagree

Trust the manual read of the actual runtime path over any single score. In the
`enhance` case, skillspector said HIGH/DO NOT INSTALL while snyk-agent-scan found
nothing — the delta was entirely eval fixtures + install docs, and the hand read
cleared it. Document *why* they disagreed in the report.

## Side effects to disclose even when SAFE (informed consent)

Report these so the user consents knowingly, regardless of verdict:
- files/dirs written, and where (CWD vs. `~/.claude` vs. system paths);
- local config changed (`settings.json`, keybindings, env vars);
- network access performed (API calls, web search/fetch) and to where;
- extra model/API calls or costs the artifact incurs;
- required permissions / tools the artifact expects.
