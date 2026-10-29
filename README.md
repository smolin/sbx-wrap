# Using Docker Sandbox (sbx) with OpenCode

Building on https://www.docker.com/products/docker-sandboxes/, for opencode
(but with suitable updates to Dockerfile, application more generally).

A Dockerfile builds to an image that is converted to a template and passed with
the --template argument, adding useful utilities like Playwright.

Agent skills and opencode config are included by mounting `~/.agents/` and
`~/.config/opencode/` (readonly). Because those mounts land at the
host-mirrored path (`/Users/<you>/...`) while opencode reads `$HOME`
(`/home/agent`), the sbx 'kit' symlinks the mounted trees into `$HOME` at setup
time. Skills and config are therefore live and single-sourced rather than
copied (copies go stale).

An AGENTS.md file is included by the same mount; the kit also copies it to a
distinct ancestor of the working directory, so harnesses that walk up the tree
(such as opencode) load it in addition to the sbx-generated profile.

A bash function found in sbx-wrap-function.sh uses the CWD inode for a unique
sandbox name. On first run, it uses --detached, --template and --kit, then runs
sbx again to attach. On subsequent runs, it reuses the existing container.



## Prerequisites

- Docker with `buildx`
- [Task](https://taskfile.dev/) CLI
- `sbx` CLI
- this project, cloned to ~/resources/sbx-wrap (b/c of bash function)
- (optional, for the `context` MCP demo) [neuledge/context](https://github.com/neuledge/context), cloned to ~/resources/context


## Opencode and Zen

Ref https://docs.docker.com/ai/sandboxes/agents/opencode/#opencode-zen-api-keys

When using an OpenCode Zen subscription (OpenCode Go subscription details left
as an exercise to the reader), you need to use 'sbx secret set-custom' and
provide your API key:

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



### Rotating the key

The key is injected into sandboxes as the `OPENCODE_API_KEY` env var via the
global custom secret above. When you rotate your OpenCode key, the secret still
holds the old value, so sandboxes fall back to prompting for `/connect` on
every session. Update the secret to the new key:

```
# set-custom refuses to overwrite an existing secret, so remove it first
sbx secret rm --placeholder <old-placeholder> -f
sbx secret set-custom \
    --host opencode.ai \
    --env OPENCODE_API_KEY \
    --value "$OPENCODE_API_KEY"
```

Find the old placeholder with `sbx secret ls`. Note that existing sandboxes may
still have the old placeholder baked into their `OPENCODE_API_KEY` env var; if
a reused sandbox still prompts for `/connect`, recreate it so it picks up the
new placeholder.

The rotated key itself lives in `~/.local/share/opencode/auth.json`, which the
`sbx-wrap` function does not mount (it only mounts `~/.config/opencode:ro` and
`~/.agents:ro`). That is why the secret is the source of truth for the sandbox,
not the host auth file.



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



## MCP servers

`sbx mcp add` registers a server on the host; `sbx mcp load ... --sandbox <name>`
attaches an already-registered server to a running sandbox. How you register a
server depends on its transport:

- **stdio servers** (e.g. `everything`) are launched by `sbx` itself via
  `--command`/`--args`:

  ```bash
  task sbx-mcp-demo-add
  ```

- **HTTP servers** (e.g. [neuledge/context](https://github.com/neuledge/context),
  run via its own Docker image on `localhost:8080`) are already running
  processes that `sbx` just connects to via `--url`. Build/run the container
  once (expects `neuledge/context` cloned to `~/resources/context`), then
  register it:

  ```bash
  task build-context-image   # once, or after pulling updates
  task context-serve         # starts the container in the background
  task sbx-mcp-demo-add-context
  ```

Either way, `sbx mcp load <name> --sandbox "$sandbox_name"` in the bash
function above is what actually exposes the server to a given sandbox.

