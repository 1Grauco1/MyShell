#!/usr/bin/env bash

# Define paths (overridable via env for portability)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
G_ANT_SHELL_DIR="${G_ANT_SHELL_DIR:-$(dirname "$SCRIPT_DIR")}"

if [ -n "${G_ANT_REPO_DIR:-}" ] && [ -d "$G_ANT_REPO_DIR/.git" ]; then
    G_ANT_DIR="$G_ANT_REPO_DIR"
elif [ -d "$HOME/Documents/Dots/g_ant/.git" ]; then
    G_ANT_DIR="$HOME/Documents/Dots/g_ant"
else
    G_ANT_DIR="$HOME/g_ant"
fi

check_repo() {
    local dir=$1
    local name=$2
    if [ -d "$dir/.git" ]; then
        cd "$dir" || return
        # Try to fetch updates with a timeout
        if command -v timeout >/dev/null 2>&1; then
            timeout 10s git fetch > /dev/null 2>&1
        else
            git fetch > /dev/null 2>&1
        fi
        
        if [ $? -eq 0 ]; then
            local count=$(git rev-list --count HEAD..@{u} 2>/dev/null)
            local commits="[]"
            if [ -n "$count" ] && [ "$count" -gt 0 ]; then
                # Get last 5 commit titles and dates
                commits=$(git log HEAD..@{u} --pretty=format:'{"title":"%s", "date":"%cr"}' -n 5 | jq -s .)
            fi
            
            if [ -z "$count" ]; then
                echo "{\"name\": \"$name\", \"exists\": true, \"updates\": 0, \"error\": \"No upstream\", \"commits\": []}"
            else
                echo "{\"name\": \"$name\", \"exists\": true, \"updates\": $count, \"commits\": $commits}"
            fi
        else
            echo "{\"name\": \"$name\", \"exists\": true, \"updates\": 0, \"error\": \"Fetch failed\", \"commits\": []}"
        fi
    else
        echo "{\"name\": \"$name\", \"exists\": false, \"updates\": 0, \"commits\": []}"
    fi
}

g_ant_status=$(check_repo "$G_ANT_DIR" "g_ant")
g_ant_shell_status=$(check_repo "$G_ANT_SHELL_DIR" "g_ant-shell")

jq -n \
    --argjson g_ant "$g_ant_status" \
    --argjson g_ant_shell "$g_ant_shell_status" \
    '{g_ant: $g_ant, g_ant_shell: $g_ant_shell}'
