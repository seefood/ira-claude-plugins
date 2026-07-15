# Known JSON-emitting commands

Programs and flag patterns known to emit JSON. Check here before deciding
whether a command's output should be piped through `scripts/json2toon.py`.

When you run a command not listed here and observe it emitting JSON (a flag
like `--json`, `--output json`, `-o json`, `-o=json`, or JSON-shaped stdout
by default), add a row below so future sessions recognize it without
rediscovery. Keep entries one line each: program, the flag/condition that
triggers JSON output, and one example invocation.

| Program | JSON trigger | Example |
|---|---|---|
| aws (AWS CLI) | default output, or explicit `--output json` | `aws ec2 describe-instances --output json \| json2toon.py` |
| gh (GitHub CLI) | `gh api ...`, or `--json <fields>` on other subcommands | `gh api repos/o/r/pulls \| json2toon.py` |
| kubectl | `-o json` | `kubectl get pods -o json \| json2toon.py` |
| terraform / tofu | `-json` on `plan`/`show`/`output` | `terraform show -json tfplan \| json2toon.py` |
| docker | `inspect` (always JSON), `--format json` | `docker inspect <container> \| json2toon.py` |
| npm | `--json` on `ls`, `outdated`, `audit` | `npm ls --json \| json2toon.py` |
| snyk-agent-scan | `--json` | `snyk-agent-scan --json \| json2toon.py` |
| jq | any `jq` filter (already JSON in, JSON out by default) | `curl ... \| jq . \| json2toon.py` |
| mnemon | unconfirmed — verify actual flag on first use, then update this row | `mnemon ??? \| json2toon.py` |
