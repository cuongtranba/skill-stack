#!/usr/bin/env python3
"""Report the front matter of every skills/*/SKILL.md as JSON lines.

The skills CLI (https://github.com/vercel-labs/skills) parses SKILL.md front
matter with a real YAML parser and silently drops any skill that fails to parse
or whose `name`/`description` are not strings. A skill dropped that way is
simply absent from `npx skills add` with no error the author will notice, so
this check has to reproduce the parser's strictness.

Emits one JSON object per skill directory:
    {"dir": "golang", "name": ..., "internal": false, "error": null}

PyYAML is used when importable. It usually is not, so the fallback parser must
be able to reject the same inputs -- above all a plain (unquoted) scalar
containing ": ", which YAML reads as a nested mapping rather than as text.
"""

import json
import os
import re
import sys

try:
    import yaml

    HAVE_YAML = True
except ImportError:
    HAVE_YAML = False

FRONTMATTER = re.compile(r"\A---[ \t]*\r?\n(.*?)\r?\n---[ \t]*\r?\n", re.S)
TOP_LEVEL = re.compile(r"^([^:\s]+):(?:[ \t]+(.*))?$")
NESTED = re.compile(r"^[ \t]+([^:\s]+):(?:[ \t]+(.*))?$")


def _scalar(value):
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    if value in ("true", "True"):
        return True
    if value in ("false", "False"):
        return False
    if ": " in value or value.endswith(":"):
        raise ValueError(
            "unquoted value contains ':' and is not valid as a YAML plain "
            "scalar -- wrap it in single quotes: %s" % value
        )
    return value


def _parse_fallback(block):
    """Parse the small subset of YAML that SKILL.md front matter may use."""
    data = {}
    lines = block.split("\n")
    index = 0
    while index < len(lines):
        line = lines[index]
        index += 1
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line[:1].isspace():
            raise ValueError("unexpected indentation: %s" % line.strip())

        match = TOP_LEVEL.match(line)
        if not match:
            raise ValueError("cannot parse line: %s" % line.strip())
        key, raw = match.group(1), (match.group(2) or "").strip()

        if raw:
            data[key] = _scalar(raw)
            continue

        child = {}
        while index < len(lines) and (
            not lines[index].strip() or lines[index][:1].isspace()
        ):
            sub = lines[index]
            index += 1
            if not sub.strip():
                continue
            sub_match = NESTED.match(sub)
            if not sub_match:
                raise ValueError("cannot parse nested line: %s" % sub.strip())
            child[sub_match.group(1)] = _scalar((sub_match.group(2) or "").strip())
        data[key] = child
    return data


def inspect(path):
    with open(path, encoding="utf-8") as handle:
        content = handle.read()

    match = FRONTMATTER.match(content)
    if not match:
        raise ValueError("no '---' front matter block at the top of the file")

    block = match.group(1)
    data = yaml.safe_load(block) if HAVE_YAML else _parse_fallback(block)

    if not isinstance(data, dict):
        raise ValueError("front matter is not a mapping")
    for field in ("name", "description"):
        if field not in data:
            raise ValueError("missing required front matter field: %s" % field)
        if not isinstance(data[field], str):
            raise ValueError(
                "front matter '%s' must be a string (got %s)"
                % (field, type(data[field]).__name__)
            )
    return data


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    skills_dir = os.path.join(root, "skills")

    for name in sorted(os.listdir(skills_dir)):
        path = os.path.join(skills_dir, name, "SKILL.md")
        if not os.path.isfile(path):
            continue

        record = {"dir": name, "name": None, "internal": False, "error": None}
        try:
            data = inspect(path)
            metadata = data.get("metadata")
            record["name"] = data["name"]
            record["internal"] = (
                isinstance(metadata, dict) and metadata.get("internal") is True
            )
        except (ValueError, OSError) as error:
            record["error"] = str(error).split("\n")[0]
        print(json.dumps(record))


if __name__ == "__main__":
    main()
