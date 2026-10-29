# sbx is a sandboxing tool for AI utilites, but does not natively
# support opencode.
#
# Run once per system:
#     sbx policy allow network opencode.ai:443
#
# skills; AGENTS.md; opencode.json
#
# MCP: you could add lines like 'sbx mcp load context --sandbox
# "$sandbox_name"' after 'sbx run' but that makes them active
# unconditionally. Maybe stick with running 'mcp-add <name>' in
# the session. But run 'sbx mcp add ...' first, once per workstation.
#
# Home: In the 'run' command we include ~/.agents (and others) but this lands
# at /Users/<you-on-host>/.agents; inside the container, the process runs as
# user "agent" but with CWD underneath /home/<you-on-host>. The 'kit' is meant
# to handle this discrepency.
#
function sbx-wrap ()
{
    local sandbox_name base
    base="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr ' _' '--' | tr -cd 'a-z0-9-' | tr -s '-')"
    [ -n "$base" ] || base="root"
    sandbox_name="$base-$(ls -id . | awk '{print $1}')"
    if sbx ls 2> /dev/null | grep -q "^${sandbox_name}[[:space:]]"; then
        echo "sandbox exists, reusing"
    else
        echo "creating sandbox for $sandbox_name"
        sbx run -t sbx-opencode:latest opencode . ~/.agents:ro ~/.config/opencode:ro \
            --name "$sandbox_name" \
            --kit /Users/"$USER"/resources/sbx-wrap/my-kit \
            --detach
    fi
    # Because opencode nerfs the terminal buffer:
    echo 'Available MCP services (use "mcp-add <name>" to load):'
    sbx mcp ls
    tput smcup ; trap 'tput rmcup' RETURN
    sbx run opencode --name "$sandbox_name"
}


