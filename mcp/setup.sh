#!/usr/bin/env bash
# shellsmith MCP server setup
# Reads JSON templates from mcp/ dir, substitutes env vars, and writes
# to Claude Code's global config (~/.claude.json mcpServers section).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_CONFIG="$HOME/.claude.json"
AVAILABLE_SERVERS=()
SELECTED_SERVERS=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Discover available MCP server templates
for f in "$SCRIPT_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f" .json)"
    AVAILABLE_SERVERS+=("$name")
done

if [[ ${#AVAILABLE_SERVERS[@]} -eq 0 ]]; then
    echo -e "${RED}No MCP server templates found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Show menu
echo -e "${CYAN}shellsmith MCP setup${NC}"
echo ""
echo "Available MCP servers:"
for i in "${!AVAILABLE_SERVERS[@]}"; do
    name="${AVAILABLE_SERVERS[$i]}"
    desc=$(python3 -c "
import json, sys
with open('$SCRIPT_DIR/$name.json') as f:
    d = json.load(f)
key = list(d.keys())[0]
print(d[key].get('description', ''))
" 2>/dev/null || echo "")
    echo -e "  ${GREEN}$((i+1)))${NC} $name — $desc"
done
echo ""

# Parse arguments or prompt
if [[ $# -gt 0 ]]; then
    SELECTED_SERVERS=("$@")
else
    echo -n "Enter server names (space-separated) or 'all': "
    read -r selection
    if [[ "$selection" == "all" ]]; then
        SELECTED_SERVERS=("${AVAILABLE_SERVERS[@]}")
    else
        read -ra SELECTED_SERVERS <<< "$selection"
    fi
fi

# Validate selections
for srv in "${SELECTED_SERVERS[@]}"; do
    if [[ ! -f "$SCRIPT_DIR/$srv.json" ]]; then
        echo -e "${RED}Unknown server: $srv${NC}"
        exit 1
    fi
done

# Ensure claude config exists
if [[ ! -f "$CLAUDE_CONFIG" ]]; then
    echo '{}' > "$CLAUDE_CONFIG"
fi

# Process each selected server
for srv in "${SELECTED_SERVERS[@]}"; do
    template="$SCRIPT_DIR/$srv.json"
    echo ""
    echo -e "${CYAN}Configuring: $srv${NC}"

    # Read the template and extract env placeholders
    server_json=$(cat "$template")
    key=$(python3 -c "import json; d=json.load(open('$template')); print(list(d.keys())[0])")

    # Check for requires field
    requires=$(python3 -c "
import json
d = json.load(open('$template'))
key = list(d.keys())[0]
print(d[key].get('requires', ''))
" 2>/dev/null || echo "")

    if [[ -n "$requires" ]]; then
        echo -e "  ${YELLOW}prerequisite:${NC} $requires"
    fi

    # Find placeholders (__SOMETHING__) and prompt for values
    placeholders=$(grep -oE '__[A-Z_]+__' "$template" 2>/dev/null | sort -u || true)

    resolved_json="$server_json"
    skip=false
    for ph in $placeholders; do
        # Convert __JIRA_SITE__ → JIRA_SITE for display
        var_name="${ph//__/}"

        # Check if already set in environment
        env_val="${!var_name:-}"
        if [[ -n "$env_val" ]]; then
            echo -e "  ${GREEN}$var_name${NC}: using env value"
            resolved_json="${resolved_json//$ph/$env_val}"
        else
            echo -n "  $var_name: "
            read -r user_val
            if [[ -z "$user_val" ]]; then
                echo -e "  ${YELLOW}skipping $srv (no value provided)${NC}"
                skip=true
                break
            fi
            resolved_json="${resolved_json//$ph/$user_val}"
        fi
    done

    if [[ "$skip" == "true" ]]; then
        continue
    fi

    # Merge into Claude Code config using python
    python3 -c "
import json, sys

with open('$CLAUDE_CONFIG', 'r') as f:
    config = json.load(f)

template = json.loads('''$resolved_json''')
key = list(template.keys())[0]

# Build clean server entry (command, args, env only)
entry = {}
for field in ('command', 'args', 'env'):
    if field in template[key]:
        entry[field] = template[key][field]

# Write to mcpServers at top level
if 'mcpServers' not in config:
    config['mcpServers'] = {}
config['mcpServers'][key] = entry

with open('$CLAUDE_CONFIG', 'w') as f:
    json.dump(config, f, indent=2)
"
    echo -e "  ${GREEN}✓ $srv added to ~/.claude.json${NC}"
done

echo ""
echo -e "${GREEN}MCP setup complete.${NC} Restart Claude Code or Pi to pick up changes."
