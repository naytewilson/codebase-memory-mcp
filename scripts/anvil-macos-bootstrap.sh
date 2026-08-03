#!/usr/bin/env bash
# Install and configure codebase-memory-mcp for the MacBrains ANVIL workflow.
# macOS only. Pure shell; no Python, Docker, or package-manager dependency.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
MODE="release"
VARIANT="ui"
INDEX_PROJECTS=1
INSTALL_LAUNCHER=1
DRY_RUN=0
INSTALL_DIR="${CBM_INSTALL_DIR:-$HOME/.local/bin}"
PROJECTS=()

usage() {
    cat <<'USAGE'
Usage: scripts/anvil-macos-bootstrap.sh [options]

Options:
  --release             Install the latest checksum-verified upstream release.
                        This is the default and preserves the fork as an overlay.
  --source              Build the current checkout and install that binary.
  --ui                   Install the graph UI build (default).
  --headless             Install the standard build without the embedded UI.
  --project PATH         Explicitly index one repository/worktree after install.
                        Repeat for multiple active roots.
  --no-index             Install and configure only; skip project indexing.
  --no-launcher          Do not create ~/Applications/Codebase Memory Graph.command.
  --install-dir PATH     Binary destination (default: ~/.local/bin).
  --dry-run              Print mutating commands without executing them.
  -h, --help             Show this help.

MacBrains defaults:
  auto_index=false
  auto_watch=false

The native installer configures detected MCP clients. Restart open clients after
this script completes so they launch the installed build and hooks.
USAGE
}

print_command() {
    printf '+'
    printf ' %q' "$@"
    printf '\n'
}

run() {
    print_command "$@"
    if [ "$DRY_RUN" -eq 0 ]; then
        "$@"
    fi
}

fail() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

append_project() {
    [ -n "$1" ] || fail "--project requires a non-empty path"
    PROJECTS+=("$1")
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --release)
            MODE="release"
            ;;
        --source)
            MODE="source"
            ;;
        --ui)
            VARIANT="ui"
            ;;
        --headless|--standard)
            VARIANT="standard"
            ;;
        --project)
            [ "$#" -ge 2 ] || fail "--project requires a path"
            shift
            append_project "$1"
            ;;
        --project=*)
            append_project "${1#--project=}"
            ;;
        --no-index)
            INDEX_PROJECTS=0
            ;;
        --no-launcher)
            INSTALL_LAUNCHER=0
            ;;
        --install-dir)
            [ "$#" -ge 2 ] || fail "--install-dir requires a path"
            shift
            INSTALL_DIR="$1"
            ;;
        --install-dir=*)
            INSTALL_DIR="${1#--install-dir=}"
            ;;
        --dry-run)
            DRY_RUN=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            fail "unknown option: $1"
            ;;
    esac
    shift
done

[ "$(uname -s)" = "Darwin" ] || fail "this bootstrap is macOS-only"
command -v git >/dev/null 2>&1 || fail "git is required"
[ -f "$ROOT/install.sh" ] || fail "run this script from a complete codebase-memory-mcp checkout"
[ -f "$ROOT/AGENTS.md" ] || fail "MacBrains AGENTS.md overlay is missing"

REPO_ROOT="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)" ||
    fail "$ROOT is not a Git checkout"
REPO_ROOT="$(cd "$REPO_ROOT" && pwd -P)"
[ "$REPO_ROOT" = "$ROOT" ] || fail "script root and Git root disagree"

BRANCH="$(git -C "$ROOT" symbolic-ref --quiet --short HEAD 2>/dev/null || printf 'DETACHED')"
HEAD="$(git -C "$ROOT" rev-parse HEAD)"
DIRTY_COUNT="$(git -C "$ROOT" status --porcelain | wc -l | tr -d '[:space:]')"

printf '%s\n' '=== MacBrains CBM source-truth preflight ==='
printf 'root:       %s\n' "$ROOT"
printf 'branch:     %s\n' "$BRANCH"
printf 'head:       %s\n' "$HEAD"
printf 'dirty:      %s path(s)\n' "$DIRTY_COUNT"
printf 'host arch:  %s\n' "$(uname -m)"
printf 'mode:       %s\n' "$MODE"
printf 'variant:    %s\n' "$VARIANT"
printf 'install:    %s\n' "$INSTALL_DIR"
printf '\nworktrees:\n'
git -C "$ROOT" worktree list --porcelain
printf '\n'

if [ "$MODE" = "release" ]; then
    INSTALL_ARGS=("--dir" "$INSTALL_DIR")
    if [ "$VARIANT" = "ui" ]; then
        INSTALL_ARGS+=("--ui")
    else
        INSTALL_ARGS+=("--standard")
    fi
    run bash "$ROOT/install.sh" "${INSTALL_ARGS[@]}"
else
    BUILD_ARGS=()
    if [ "$VARIANT" = "ui" ]; then
        BUILD_ARGS+=("--with-ui")
    fi
    run "$ROOT/scripts/build.sh" "${BUILD_ARGS[@]}"
    SOURCE_BINARY="$ROOT/build/c/codebase-memory-mcp"
    if [ "$DRY_RUN" -eq 0 ]; then
        [ -x "$SOURCE_BINARY" ] || fail "source build did not produce $SOURCE_BINARY"
    fi
    run "$SOURCE_BINARY" install -y --force "--dir=$INSTALL_DIR"
fi

CBM="$INSTALL_DIR/codebase-memory-mcp"
if [ "$DRY_RUN" -eq 1 ]; then
    printf '\nDry run complete; no installation, configuration, indexing, or receipt was written.\n'
    exit 0
fi

[ -x "$CBM" ] || fail "installed binary is missing or not executable: $CBM"
VERSION="$("$CBM" --version 2>&1)" || fail "installed binary failed to execute"
printf 'installed:  %s\n' "$VERSION"

# Deliberately explicit indexing. ANVIL has many worktrees and the Neo has a
# tight memory budget; background registration of every visited worktree is not
# an acceptable default.
run "$CBM" config set auto_index false
run "$CBM" config set auto_watch false

# Make the CLI available in future login shells without duplicating a managed
# block. MCP client configs use the installer's absolute executable path, so a
# PATH change is convenience rather than a correctness dependency.
ZSH_HOME="${ZDOTDIR:-$HOME}"
ZPROFILE="$ZSH_HOME/.zprofile"
PATH_MARKER='# MacBrains codebase-memory-mcp PATH'
if ! printf '%s' "$PATH" | tr ':' '\n' | grep -Fqx "$INSTALL_DIR"; then
    mkdir -p "$ZSH_HOME"
    if [ ! -f "$ZPROFILE" ] || ! grep -Fq "$PATH_MARKER" "$ZPROFILE"; then
        {
            printf '\n%s\n' "$PATH_MARKER"
            printf 'export PATH=%q:$PATH\n' "$INSTALL_DIR"
        } >> "$ZPROFILE"
        printf 'updated:    %s\n' "$ZPROFILE"
    fi
fi

LAUNCHER=""
if [ "$INSTALL_LAUNCHER" -eq 1 ] && [ "$VARIANT" = "ui" ]; then
    LAUNCHER_DIR="$HOME/Applications"
    LAUNCHER="$LAUNCHER_DIR/Codebase Memory Graph.command"
    LOG_DIR="$HOME/Library/Logs/MacBrains"
    mkdir -p "$LAUNCHER_DIR" "$LOG_DIR"
    {
        printf '%s\n' '#!/bin/zsh'
        printf '%s\n' 'set -eu'
        printf 'CBM=%q\n' "$CBM"
        cat <<'LAUNCHER_EOF'
PORT="${CBM_UI_PORT:-9749}"
LOG_DIR="$HOME/Library/Logs/MacBrains"
LOG_FILE="$LOG_DIR/codebase-memory-mcp-ui.log"
mkdir -p "$LOG_DIR"
if ! /usr/bin/curl -fsS --max-time 1 "http://127.0.0.1:${PORT}/" >/dev/null 2>&1; then
    /usr/bin/nohup "$CBM" --ui=true --port="$PORT" >>"$LOG_FILE" 2>&1 &
    /bin/sleep 2
fi
/usr/bin/open "http://127.0.0.1:${PORT}"
LAUNCHER_EOF
    } > "$LAUNCHER"
    chmod 755 "$LAUNCHER"
    printf 'launcher:   %s\n' "$LAUNCHER"
fi

INDEXED_ROOTS_FILE=""
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/macbrains/codebase-memory-mcp"
mkdir -p "$STATE_DIR"
INDEXED_ROOTS_FILE="$STATE_DIR/indexed-roots.txt"
: > "$INDEXED_ROOTS_FILE"

if [ "$INDEX_PROJECTS" -eq 1 ]; then
    for requested in "${PROJECTS[@]}"; do
        [ -d "$requested" ] || fail "project path does not exist: $requested"
        project_root="$(git -C "$requested" rev-parse --show-toplevel 2>/dev/null)" ||
            fail "project is not a Git worktree: $requested"
        project_root="$(cd "$project_root" && pwd -P)"
        if grep -Fqx "$project_root" "$INDEXED_ROOTS_FILE"; then
            printf 'skip duplicate project root: %s\n' "$project_root"
            continue
        fi
        run "$CBM" cli --progress index_repository --repo-path "$project_root"
        printf '%s\n' "$project_root" >> "$INDEXED_ROOTS_FILE"
    done
fi

PROJECTS_JSON="$STATE_DIR/projects.json"
if ! "$CBM" cli list_projects > "$PROJECTS_JSON" 2> "$STATE_DIR/list-projects.stderr"; then
    fail "list_projects verification failed; see $STATE_DIR/list-projects.stderr"
fi

RECEIPT="$STATE_DIR/last-bootstrap.md"
{
    printf '# MacBrains codebase-memory-mcp bootstrap receipt\n\n'
    printf -- '- timestamp_utc: `%s`\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf -- '- host: `%s`\n' "$(hostname)"
    printf -- '- repository: `%s`\n' "$ROOT"
    printf -- '- branch: `%s`\n' "$BRANCH"
    printf -- '- head: `%s`\n' "$HEAD"
    printf -- '- starting_dirty_paths: `%s`\n' "$DIRTY_COUNT"
    printf -- '- install_mode: `%s`\n' "$MODE"
    printf -- '- variant: `%s`\n' "$VARIANT"
    printf -- '- binary: `%s`\n' "$CBM"
    printf -- '- version: `%s`\n' "$VERSION"
    printf -- '- auto_index: `false`\n'
    printf -- '- auto_watch: `false`\n'
    if [ -n "$LAUNCHER" ]; then
        printf -- '- graph_ui_launcher: `%s`\n' "$LAUNCHER"
    else
        printf -- '- graph_ui_launcher: `not installed`\n'
    fi
    printf -- '- indexed_roots: `%s`\n' "$INDEXED_ROOTS_FILE"
    printf -- '- list_projects_output: `%s`\n' "$PROJECTS_JSON"
    printf '\n## Evidence boundary\n\n'
    printf '%s\n' 'The native installer completed and the installed binary executed successfully.'
    printf '%s\n' 'The configuration write commands for explicit indexing completed successfully.'
    printf '%s\n' 'Each supplied project root completed the native index command before it was recorded.'
    printf '%s\n' 'Open coding clients still need to be restarted before their new MCP process and hooks are proven active.'
} > "$RECEIPT"

printf '\n=== Verification ===\n'
printf 'version:     %s\n' "$VERSION"
printf 'projects:    %s\n' "$PROJECTS_JSON"
printf 'receipt:     %s\n' "$RECEIPT"
if [ -n "$LAUNCHER" ]; then
    printf 'open UI:     %s\n' "$LAUNCHER"
fi
printf '\nRestart open coding clients, then verify that codebase-memory-mcp is connected before repository work.\n'
