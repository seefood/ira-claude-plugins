#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Convert JSON to TOON (Token-Oriented Object Notation).

Reads JSON from a file argument or stdin, writes TOON to stdout.

This is a from-scratch, stdlib-only implementation of the TOON encoding
idea (not verified against the upstream toon-format spec byte-for-byte):
uniform arrays of objects become a `key[N]{field,...}:` header with
comma-joined rows, scalars become `key: value`, everything else nests
with 2-space indentation. Goal is token reduction for LLM ingestion of
JSON that a human never needs to see verbatim, not perfect round-tripping.

Usage:
    json2toon.py input.json
    some-command --json | json2toon.py
"""
import json
import sys

INDENT = "  "


def needs_quoting(s):
    if s == "":
        return True
    if s.strip() != s:
        return True
    if any(c in s for c in (",", ":", "\n", "{", "}", "[", "]")):
        return True
    if s in ("true", "false", "null"):
        return True
    try:
        float(s)
        return True
    except ValueError:
        return False


def scalar(value):
    if value is None:
        return "null"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, (int, float)):
        return json.dumps(value)
    if isinstance(value, str):
        return json.dumps(value) if needs_quoting(value) else value
    raise TypeError(f"not a scalar: {value!r}")


def is_scalar(value):
    return value is None or isinstance(value, (bool, int, float, str))


def uniform_object_keys(items):
    """Return the shared key order if every item is a dict of scalars with
    identical keys, else None."""
    if not items or not all(isinstance(i, dict) for i in items):
        return None
    keys = list(items[0].keys())
    for item in items:
        if list(item.keys()) != keys:
            return None
        if not all(is_scalar(v) for v in item.values()):
            return None
    return keys


def encode_array(key_prefix, arr, depth, lines):
    n = len(arr)
    keys = uniform_object_keys(arr)
    if keys is not None:
        header = f"{key_prefix}[{n}]{{{','.join(keys)}}}:"
        lines.append(INDENT * depth + header)
        for item in arr:
            row = ",".join(scalar(item[k]) for k in keys)
            lines.append(INDENT * (depth + 1) + row)
        return
    if all(is_scalar(v) for v in arr):
        row = ",".join(scalar(v) for v in arr)
        lines.append(INDENT * depth + f"{key_prefix}[{n}]: {row}")
        return
    lines.append(INDENT * depth + f"{key_prefix}[{n}]:")
    for item in arr:
        encode_list_item(item, depth + 1, lines)


def encode_list_item(value, depth, lines):
    prefix = INDENT * depth + "- "
    if isinstance(value, dict):
        first = True
        for k, v in value.items():
            if first:
                encode_pair(k, v, depth, lines, first_prefix=prefix)
                first = False
            else:
                encode_pair(k, v, depth + 1, lines)
    elif isinstance(value, list):
        lines.append(prefix.rstrip())
        encode_array("", value, depth + 1, lines)
    else:
        lines.append(prefix + scalar(value))


def encode_pair(key, value, depth, lines, first_prefix=None):
    indent = first_prefix if first_prefix is not None else INDENT * depth
    if is_scalar(value):
        lines.append(f"{indent}{key}: {scalar(value)}")
    elif isinstance(value, list):
        if not value:
            lines.append(f"{indent}{key}[0]:")
        else:
            tmp = []
            encode_array(key, value, 0, tmp)
            lines.append(indent + tmp[0])
            lines.extend(INDENT * depth + t for t in tmp[1:])
    elif isinstance(value, dict):
        if not value:
            lines.append(f"{indent}{key}:")
        else:
            lines.append(f"{indent}{key}:")
            encode_object(value, depth + 1, lines)
    else:
        raise TypeError(f"unsupported value: {value!r}")


def encode_object(obj, depth, lines):
    for k, v in obj.items():
        encode_pair(k, v, depth, lines)


def to_toon(data):
    lines = []
    if isinstance(data, dict):
        encode_object(data, 0, lines)
    elif isinstance(data, list):
        encode_array("", data, 0, lines)
    else:
        lines.append(scalar(data))
    return "\n".join(lines) + "\n"


def main():
    if len(sys.argv) > 1:
        with open(sys.argv[1]) as f:
            data = json.load(f)
    else:
        data = json.load(sys.stdin)
    sys.stdout.write(to_toon(data))


if __name__ == "__main__":
    main()
