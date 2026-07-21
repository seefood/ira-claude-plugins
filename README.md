# ira-claude-plugins

Personal [Claude Code](https://code.claude.com) skills, published as an
installable plugin marketplace.

## Install

```
/plugin marketplace add seefood/ira-claude-plugins
/plugin install test-before-install@ira-claude-plugins
/plugin install json-to-toon@ira-claude-plugins
/plugin install debugging-with-the-scientific-method@ira-claude-plugins
```

## Plugins

### test-before-install

Vet a third-party agent artifact (Claude Code skill, plugin, MCP server) or a
local "enhancement" from a remote or external source before installing it
locally. Fetches the source read-only into quarantine, runs static and
type-appropriate scanners in isolation, verifies findings by hand, and reports
a verdict with the side effects to consent to.

See [`plugins/test-before-install/skills/test-before-install/SKILL.md`](plugins/test-before-install/skills/test-before-install/SKILL.md).

### json-to-toon

Converts JSON command output (AWS CLI, `kubectl -o json`, `terraform show
-json`, `snyk-agent-scan --json`, etc.) to compact TOON notation before it
enters the conversation, to save ingestion tokens. Skips conversion when the
raw JSON itself is the deliverable (editing, piping to another JSON
consumer, saving for later). Maintains a living registry of known
JSON-emitting commands that grows as new ones are discovered.

See [`plugins/json-to-toon/skills/json-to-toon/SKILL.md`](plugins/json-to-toon/skills/json-to-toon/SKILL.md).

Measured token savings on real command output (`tiktoken`, `cl100k_base` /
`o200k_base` — an approximation of the actual Sonnet 5 tokenizer, not an
exact count):

| Source | JSON tokens | TOON tokens | Savings |
|---|---|---|---|
| `mnemon status` (tabular) | 481 | 195 | 59.5% |
| `mnemon search` (free-text) | 2521 | 2310 | 8.4% |

Savings scale with how tabular the data is: uniform arrays of objects
collapse into `key[N]{fields}:` header + rows, while prose-heavy fields
(e.g. long `content` strings) don't compress much beyond removing JSON
punctuation.

### debugging-with-the-scientific-method

Replaces ad hoc "try this, try that" debugging with a written lab-notebook
log of hypothesis, experiment, and result — one falsifiable hypothesis at a
time, forcing precision and preventing repeated dead ends.

See [`plugins/debugging-with-the-scientific-method/skills/debugging-with-the-scientific-method/SKILL.md`](plugins/debugging-with-the-scientific-method/skills/debugging-with-the-scientific-method/SKILL.md).

## Repository layout

Follows the [Claude Code plugin marketplace schema](https://code.claude.com/docs/en/plugin-marketplaces):

```
.claude-plugin/marketplace.json    - marketplace manifest
plugins/<name>/.claude-plugin/plugin.json  - per-plugin manifest
plugins/<name>/skills/<name>/SKILL.md      - the skill itself
```

## License

MIT, see [LICENSE](LICENSE).
