#!/usr/bin/env bash
# Verify the coexist layout: both the sbx profile and the user AGENTS.md are
# present, the kit file carries the breadcrumb, and (when the ~/.agents:ro host
# mount is visible) it matches the live host file and the $HOME symlink bridge
# resolves back to the mount. Run inside the sandbox:
#   sbx exec <sandbox> -- bash /home/agent/.agents/verify.sh
set -eu

ws="${WORKSPACE_DIR:-$(findmnt -n -o TARGET -t virtiofs 2>/dev/null | head -n1)}"
parent="$(dirname "$ws")"
profile="$parent/AGENTS.md"

dest=""
mount_src=""
case "$ws" in
  /Users/*|/home/*)
    home="$(printf '%s' "$ws" | cut -d/ -f1-3)"
    if [ "$home" != "$parent" ]; then
      dest="$home/AGENTS.md"
    fi
    mount_src="$home/.agents/AGENTS.md"
    ;;
esac
if [ -z "$dest" ]; then
  dest="$(dirname "$parent")/AGENTS.md"
fi

fail=0
check() {
  local label="$1" file="$2"
  if [ -f "$file" ]; then
    echo "ok   $label: $file"
  else
    echo "FAIL $label: $file missing" >&2
    fail=1
  fi
}
check_link() {
  local label="$1" link="$2" target="$3"
  if [ ! -e "$target" ]; then
    echo "skip $label: host source absent ($target)"
  elif [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
    echo "ok   $label: $link -> $target"
  else
    echo "FAIL $label: $link not linked to $target" >&2
    fail=1
  fi
}

check "sbx profile" "$profile"
check "kit file   " "$dest"

if [ -n "$mount_src" ]; then
  if [ -f "$mount_src" ]; then
    if cmp -s "$dest" "$mount_src"; then
      echo "ok   kit file matches live host mount $mount_src"
    else
      echo "FAIL kit file differs from live host mount $mount_src (stale source)" >&2
      fail=1
    fi
  else
    echo "warn host mount $mount_src not visible; install used kit copy or skipped" >&2
  fi

  # Symlink bridge: $HOME entries must resolve to the live host mount.
  check_link "skills bridge" /home/agent/.agents/skills "$home/.agents/skills"
  check_link "config rules bridge" /home/agent/.config/opencode/AGENTS.md "$home/.config/opencode/AGENTS.md"
fi

if grep -q 'AGENTS.md=0xF73B2' "$dest"; then
  echo "ok   breadcrumb in $dest"
else
  echo "FAIL breadcrumb 'AGENTS.md=0xF73B2' not in $dest" >&2
  fail=1
fi

exit "$fail"