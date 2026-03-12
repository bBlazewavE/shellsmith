#!/usr/bin/env python3
"""Show MCP server status from Claude Code config."""
import json
import os
import sys

config_path = os.path.expanduser("~/.claude.json")
mode = sys.argv[1] if len(sys.argv) > 1 else "short"

if not os.path.exists(config_path):
    print("  no config found")
    sys.exit(0)

with open(config_path) as f:
    config = json.load(f)

servers = config.get("mcpServers", {})
if not servers:
    if mode == "short":
        print("  none configured (run: just mcp)")
    else:
        print("  none configured")
    sys.exit(0)

for name, srv in servers.items():
    if mode == "short":
        print(f"  ok: {name}")
    else:
        cmd = srv.get("command", "?")
        args = " ".join(srv.get("args", []))
        print(f"  {name}: {cmd} {args}")
