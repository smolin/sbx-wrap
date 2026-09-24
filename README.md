# Using Docker Sandbox (sbx) with OpenCode

Building on https://www.docker.com/products/docker-sandboxes/, for opencode (but with suitable updates to Dockerfile, application more generally).

A Dockerfile builds to an image that is converted to a template and passed with the --template argument, adding useful utilities like Playwright.

Agent skills are included by mounting ~/.agents/ (readonly).

An AGENTS.md file is included by the same mount, with an sbx 'kit' providing a setup command to copy it to a parent of the working directory, to make it available to harnesses that walk up the directory tree, such as opencode.

A bash function uses the CWD inode for a unique sandbox name. On first run, it uses --detached, --template and --kit, then runs sbx again to attach. On subsequent runs, it reuses the existing container.

```
function sbx-wrap ()
{
    local sandbox_name base
    base="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr ' _' '--' | tr -cd 'a-z0-9-' | tr -s '-')"
    [ -n "$base" ] || base="root"
    sandbox_name="$base-$(ls -id . | awk '{print $1}')"

    if sbx ls 2> /dev/null | grep -q "^${sandbox_name}[[:space:]]"; then
        echo "sandbox exists, reusing"
    else
        sbx run --template sbx-opencode:latest opencode . ~/.agents:ro \
            --name "$sandbox_name" \
            --kit /Users/"$USER"/resources/sbx-wrap/my-kit \
            --detached
    fi
    sbx run opencode --name "$sandbox_name"
}
```



## Prerequisites

- Docker with `buildx`
- [Task](https://taskfile.dev/) CLI
- `sbx` CLI
- this project, cloned to ~/resources/sbx-wrap (b/c of bash function)


## Opencode and Zen

Ref https://docs.docker.com/ai/sandboxes/agents/opencode/#opencode-zen-api-keys

When using an OpenCode Zen subscription (OpenCode Go subscription details left as an exercise to the reader), you need to use 'sbx secret set-custom' and provide your API key:

```
sbx secret set-custom \
    --host opencode.ai \
    --env OPENCODE_API_KEY \
    --value "$OPENCODE_API_KEY"
Select a scope:
  1) (global)
  2) Enter sandbox name
Enter choice number: 1
Saved custom secret placeholder "sbx-<redacted>" for target "opencode.ai" env "OPENCODE_API_KEY" in scope "(global)"
Generated placeholder: sbx-<redacted>
Applied secret updates for 18 running sandbox(es)
```

Then try `sbx run opencode` (We get access to our zen subscription)



## sbx templates were broken

Ref https://github.com/docker/sbx-releases/issues/366#issuecomment-5134133137

Fixed in 0.45.1. Simple workflow suffices:

    1. First run: sbx run --template sbx-opencode:latest opencode
    2. Subsequent: sbx run opencode




## Taskfile

Build the image only:

```bash
task build
```

Build, export, and load into sbx as a reusable template:

```bash
task build-sbx-template
```

