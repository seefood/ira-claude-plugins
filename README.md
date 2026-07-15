# ira-claude-plugins

Personal [Claude Code](https://code.claude.com) skills, published as an
installable plugin marketplace.

## Install

```
/plugin marketplace add seefood/ira-claude-plugins
/plugin install test-before-install@ira-claude-plugins
```

## Plugins

### test-before-install

Vet a third-party agent artifact (Claude Code skill, plugin, MCP server) or a
local "enhancement" from a remote or external source before installing it
locally. Fetches the source read-only into quarantine, runs static and
type-appropriate scanners in isolation, verifies findings by hand, and reports
a verdict with the side effects to consent to.

See [`plugins/test-before-install/skills/test-before-install/SKILL.md`](plugins/test-before-install/skills/test-before-install/SKILL.md).

## Repository layout

Follows the [Claude Code plugin marketplace schema](https://code.claude.com/docs/en/plugin-marketplaces):

```
.claude-plugin/marketplace.json    - marketplace manifest
plugins/<name>/.claude-plugin/plugin.json  - per-plugin manifest
plugins/<name>/skills/<name>/SKILL.md      - the skill itself
```

## License

MIT, see [LICENSE](LICENSE).
