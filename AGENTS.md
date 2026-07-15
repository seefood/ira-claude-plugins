# Agent Instructions for ira-claude-plugins

A [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugin-marketplaces):
self-authored skills, packaged as installable plugins.

## Build/Lint/Test Commands

- **Lint**: `prek run --all-files`
- **Install hooks**: `prek install`
- **Validate a plugin**: `claude plugin validate plugins/<name>`
- **Test the marketplace end-to-end**:
  ```
  claude plugin marketplace add .
  claude plugin install <name>@ira-claude-plugins
  claude plugin details <name>@ira-claude-plugins
  ```

## Repository Structure

Everything here is self-authored — unlike the sister repo `dotclaude`, there
are no locked/pinned third-party snapshots, so autofix hooks (json-sort,
shfmt, trailing-whitespace) are safe to let run unrestricted.

```
.claude-plugin/marketplace.json             - marketplace manifest
plugins/<name>/.claude-plugin/plugin.json   - per-plugin manifest
plugins/<name>/skills/<name>/SKILL.md       - the skill itself
```

## Adding a new plugin

1. `mkdir -p plugins/<name>/.claude-plugin plugins/<name>/skills/<name>`
2. Write `plugins/<name>/.claude-plugin/plugin.json` (`name`, `description`,
   `version`, `author`)
3. Write the skill under `plugins/<name>/skills/<name>/SKILL.md` — see
   `skill-creator` conventions (concise SKILL.md, split large reference
   material into `references/`, scripts in `scripts/`)
4. Add an entry to `.claude-plugin/marketplace.json` (`name`, `source`,
   `description`, `version`, `author`)
5. `claude plugin validate plugins/<name>` before committing
6. Update README.md's Plugins section

## Code Style Guidelines

- JSON manifests: 2-space indentation, keys sorted (enforced by `json-sort`)
- Shell scripts under `scripts/`: `#!/bin/bash`, executable bit set,
  shellcheck/shfmt clean (enforced by prek)
