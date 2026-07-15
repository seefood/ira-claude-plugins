#!/usr/bin/env bash
# Quarantine + static triage for a candidate agent artifact (skill / plugin / MCP server).
# Fetches a source READ-ONLY into a temp dir and greps for install-time risk patterns.
# It NEVER executes anything from the source. Safe to run before installing.
#
# Usage:
#   quarantine.sh <git-url> [ref]     # shallow-clone a git repo (optional branch/tag/commit)
#   quarantine.sh <path/to/dir>       # copy a local directory (excludes .git)
#   quarantine.sh <path/to.zip>       # unzip an archive
#
# Prints: quarantine path (QUARANTINE=...), file inventory, and a triage summary.
set -euo pipefail

SRC="${1:?usage: quarantine.sh <git-url|dir|zip> [ref]}"
REF="${2:-}"
Q="$(mktemp -d "${TMPDIR:-/tmp}/tbi-quarantine.XXXXXX")"
DEST="$Q/src"
mkdir -p "$DEST"

echo "QUARANTINE=$Q"
echo "SOURCE=$SRC ${REF:+(ref $REF)}"
echo

# --- fetch (read-only, no code execution) ---------------------------------
if [[ "$SRC" =~ ^(https?|git|ssh)://|^git@|\.git$ ]]; then
	# git clone does not run repository hooks; disable local hooks path anyway.
	GIT_CONFIG_GLOBAL=/dev/null git -c core.hooksPath=/dev/null clone --depth 1 \
		${REF:+--branch "$REF"} "$SRC" "$DEST" 2>&1 | tail -2 || {
		echo "ERROR: clone failed" >&2
		exit 1
	}
	if [[ -n "$REF" ]]; then
		git -C "$DEST" fetch --depth 1 origin "$REF" 2>/dev/null &&
			git -C "$DEST" checkout -q FETCH_HEAD 2>/dev/null || true
	fi
elif [[ "$SRC" =~ \.zip$ ]]; then
	command -v unzip >/dev/null || {
		echo "ERROR: unzip not found" >&2
		exit 1
	}
	unzip -q "$SRC" -d "$DEST"
elif [[ -d "$SRC" ]]; then
	rsync -a --exclude '.git' "$SRC"/ "$DEST"/
else
	echo "ERROR: unrecognized source (expected git URL, directory, or .zip)" >&2
	exit 1
fi

CODEROOT="$DEST"

# --- inventory -------------------------------------------------------------
echo "===================== FILE INVENTORY ====================="
find "$CODEROOT" -path '*/.git' -prune -o -type f -print |
	sed "s#$CODEROOT/##" | sort
echo

# --- artifact type ---------------------------------------------------------
echo "===================== ARTIFACT TYPE ======================"
[[ -n "$(find "$CODEROOT" -name SKILL.md -not -path '*/.git/*' -print -quit)" ]] && echo "  * SKILL.md present        -> agent SKILL"
[[ -e "$CODEROOT/.claude-plugin" || -n "$(find "$CODEROOT" -name plugin.json -not -path '*/.git/*' -print -quit)" ]] && echo "  * plugin manifest present -> Claude Code PLUGIN"
[[ -n "$(find "$CODEROOT" \( -name '.mcp.json' -o -name 'mcp.json' \) -not -path '*/.git/*' -print -quit)" ]] && echo "  * mcp config present      -> MCP server config"
[[ -e "$CODEROOT/package.json" ]] && echo "  * package.json present    -> npm package (check install scripts below)"
[[ -e "$CODEROOT/pyproject.toml" || -e "$CODEROOT/setup.py" ]] && echo "  * python packaging present"
echo

# grep helper: recursive, line-numbered, skips .git and binaries, caps output
scan() {
	local label="$1" pat="$2" cap="${3:-20}"
	local hits
	hits="$(grep -rInE --binary-files=without-match \
		--exclude-dir=.git "$pat" "$CODEROOT" 2>/dev/null |
		sed "s#$CODEROOT/##" | head -n "$cap" || true)"
	if [[ -n "$hits" ]]; then
		echo "### $label"
		echo "$hits"
		echo
	fi
}

echo "===================== TRIAGE (review each hit by hand) ====================="

echo "--- Executable files (mode +x, excluding .git) ---"
find "$CODEROOT" -path '*/.git' -prune -o -type f -perm -u+x -print |
	sed "s#$CODEROOT/##" | sort || true
echo

# Install-time / auto-run surface: runs code the moment you install or load the artifact.
scan "Install-time hooks (npm/plugin/git)" '"(pre|post)install"|"install"[[:space:]]*:|hooks/|SessionStart|PreToolUse|PostToolUse|UserPromptSubmit|Stop\b'
# Remote-code-execution delivery: the classic curl|bash and friends.
scan "Pipe-to-shell / remote exec" 'curl[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh|wget[^|]*\|[[:space:]]*(ba)?sh|iwr[^|]*\|[[:space:]]*iex'
# Network egress.
scan "Network egress" '\b(curl|wget|nc|ncat|socket|/dev/tcp/|requests\.|urllib|http\.client|fetch\(|axios|XMLHttpRequest)\b'
# Obfuscation / decoded payloads (hid the enhance-eval false positive; still worth flagging).
scan "Obfuscation / encoded payloads" 'base64[[:space:]]+(-d|--decode)|\batob\(|\beval\(|\bexec\(|fromCharCode|codecs\.decode|rot13|\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}'
# Access to agent config, credentials, keys.
scan "Agent-config / credential access" '\.claude(\.json)?/|\.codex/|\.gemini/|\.cursor/|\.aws/|\.ssh/|/etc/passwd|id_rsa|\.env\b|credentials|api[_-]?key|secret|token'
# Local config/keybinding/env mutation ("enhancement" side effects).
scan "Settings / keybinding / env mutation" 'settings\.json|keybindings\.json|"VISUAL"|"EDITOR"|"env"[[:space:]]*:|crontab|launchctl|/etc/'
# Prompt-injection / instruction-override language (heuristic; expect false positives in eval fixtures).
scan "Prompt-injection language (verify: is it a test fixture?)" 'ignore (all )?(previous|prior) instructions|disregard .* instructions|override .* (safety|rules)|you are now|system prompt'

echo "===================== NEXT STEPS ====================="
echo "1. Read every file flagged above by hand; distinguish true risk from"
echo "   test fixtures / docs / license text (see references/triage.md)."
echo "2. Run type-appropriate scanners (see references/scanning-tools.md)."
echo "3. Quarantine dir: $Q   (delete with: rm -rf \"$Q\")"
