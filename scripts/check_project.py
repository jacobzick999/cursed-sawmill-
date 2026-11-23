#!/usr/bin/env python3
"""Lightweight static checks for Roblox Lua/Luau project files."""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(os.environ.get("ROBLOX_CHECK_PATH", ".")).resolve()
FAIL_ON_WARNING = os.environ.get("ROBLOX_FAIL_ON_WARNING", "false").lower() == "true"
SKIP_DIRS = {".git", ".github", "node_modules", "Packages", "build", "dist"}

def report(level: str, path: Path, message: str) -> None:
    try:
        shown = path.relative_to(ROOT)
    except ValueError:
        shown = path
    print(f"::{level} file={shown}::{message}")

def main() -> int:
    if not ROOT.exists() or not ROOT.is_dir():
        print(f"::error::Project path does not exist or is not a directory: {ROOT}")
        return 2

    lua_files = []
    for current, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            if Path(name).suffix.lower() in {".lua", ".luau"}:
                lua_files.append(Path(current) / name)

    errors = 0
    warnings = 0
    if not lua_files:
        report("warning", ROOT, "No .lua or .luau files found.")
        warnings += 1

    for file in lua_files:
        try:
            source = file.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            report("error", file, "File is not valid UTF-8.")
            errors += 1
            continue
        except OSError as exc:
            report("error", file, f"Could not read file: {exc}")
            errors += 1
            continue

        if "\x00" in source:
            report("error", file, "Contains a null byte; expected a text source file.")
            errors += 1

        # A basic delimiter check that ignores quoted strings and Lua comments.
        stack = []
        pairs = {")": "(", "]": "[", "}": "{"}
        i = 0
        quote = None
        long_comment_end = None
        line_comment = False
        while i < len(source):
            ch = source[i]
            nxt = source[i:i+2]
            if long_comment_end:
                if source.startswith(long_comment_end, i):
                    i += len(long_comment_end)
                    long_comment_end = None
                    continue
                i += 1
                continue
            if line_comment:
                if ch == "\n":
                    line_comment = False
                i += 1
                continue
            if quote:
                if ch == "\\":
                    i += 2
                    continue
                if ch == quote:
                    quote = None
                i += 1
                continue
            if nxt == "--":
                # Lua long comments: --[=[ ... ]=]
                match = re.match(r"--\[(=*)\[", source[i:])
                if match:
                    long_comment_end = "]" + match.group(1) + "]"
                    i += len(match.group(0))
                    continue
                line_comment = True
                i += 2
                continue
            if ch in ("'", '"'):
                quote = ch
            elif ch == "[":
                match = re.match(r"\[(=*)\[", source[i:])
                if match:
                    long_comment_end = "]" + match.group(1) + "]"
                    i += len(match.group(0))
                    continue
                stack.append((ch, i))
            elif ch in "({":
                stack.append((ch, i))
            elif ch in ")]}":
                if not stack or stack[-1][0] != pairs[ch]:
                    line = source.count("\n", 0, i) + 1
                    report("error", file, f"Unmatched '{ch}' near line {line}.")
                    errors += 1
                    break
                stack.pop()
            i += 1
        else:
            if quote:
                report("error", file, "Unclosed quoted string.")
                errors += 1
            if long_comment_end:
                report("error", file, "Unclosed long string or comment.")
                errors += 1
            if stack:
                opener, pos = stack[-1]
                line = source.count("\n", 0, pos) + 1
                report("error", file, f"Unclosed '{opener}' opened near line {line}.")
                errors += 1

        if re.search(r"\bloadstring\s*\(", source):
            report("warning", file, "Uses loadstring(); review carefully before running untrusted code.")
            warnings += 1
        if re.search(r"\bHttpService\b", source) and re.search(r"GetAsync|PostAsync|RequestAsync", source):
            report("warning", file, "Makes HTTP requests; verify endpoints and permissions.")
            warnings += 1

    # Validate common Rojo project manifests when present.
    manifests = list(ROOT.glob("*.project.json"))
    for manifest in manifests:
        try:
            json.loads(manifest.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
            report("error", manifest, f"Invalid Rojo project JSON: {exc}")
            errors += 1

    print(f"Roblox Project Checker: {len(lua_files)} source file(s), {errors} error(s), {warnings} warning(s).")
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a", encoding="utf-8") as handle:
            handle.write(f"files-checked={len(lua_files)}\nerrors={errors}\nwarnings={warnings}\n")

    if errors or (FAIL_ON_WARNING and warnings):
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
