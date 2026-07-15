---
name: json-to-toon
description: "Convert JSON command output to compact TOON notation before reading it into the conversation, to cut ingestion tokens for large/tabular JSON. Use whenever about to run a command whose output will be read purely for analysis/summarization and is known or observed to emit JSON - e.g. aws cli, kubectl -o json, terraform show -json, gh api, docker inspect, npm ls --json, snyk-agent-scan --json, mnemon. Do NOT use when the raw JSON bytes are the deliverable: editing a JSON file, piping into another JSON-consuming tool (jq, etc.), saving output for a human or other program, or debugging exact API/parser behavior where byte-for-byte fidelity matters."
---

# JSON to TOON

Pipes JSON-emitting command output through a bundled converter so large
structured/tabular results cost fewer tokens to read, without ever touching
the real JSON artifact the user or another tool might need.

## When to convert vs. not

Convert when the JSON is being read only so Claude can analyze, summarize,
or answer a question about it — the AWS API response, the `terraform plan
-json`, the scan results.

Do **not** convert when:
- the user is going to see/copy/edit the exact JSON
- the output is being saved to a file, committed, or passed to another
  JSON-consuming command (`jq`, a script, an API request body)
- exact byte fidelity is the point (debugging a parser, diffing a raw API
  response)

If unsure, run the command normally first with a small/limited result set;
only wrap with the converter once it's clear the output is for reading, not
handling.

## Usage

Pipe the command's stdout through the converter, or pass it a file:

```bash
aws ec2 describe-instances --output json | scripts/json2toon.py
terraform show -json tfplan | scripts/json2toon.py
scripts/json2toon.py already-saved-output.json
```

It reads JSON from stdin (or the file argument) and writes TOON to stdout.
No install step: the script is self-contained (stdlib only) and runs via
`uv run --script`, `python3`, or directly if executable.

## Known JSON emitters

Check `references/known-emitters.md` for programs/flags already confirmed
to emit JSON, with example invocations.

**When you find a new one**: if a command you're running turns out to emit
JSON (via a flag like `--json`/`--output json`/`-o json`, or JSON-shaped
stdout by default) and it isn't in the reference file yet, add a row there
(program, trigger flag, example) before moving on. This keeps the registry
current for future sessions instead of rediscovering it each time.

## Implementation note

`scripts/json2toon.py` is a from-scratch, stdlib-only implementation of the
TOON encoding idea (uniform arrays of objects → `key[N]{field,...}:` header
+ comma-joined rows; scalars → `key: value`; everything else nests with
indentation). It has not been verified against the upstream toon-format
spec for byte-for-byte compatibility — the goal here is token reduction for
Claude's own reading, not interop with other TOON consumers.
