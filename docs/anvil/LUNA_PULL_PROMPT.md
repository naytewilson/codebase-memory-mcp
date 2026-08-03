# Luna prompt: pull and activate the MacBrains CBM integration

Paste the following into Luna while it has local Mac terminal access.

---

Operate continuously until the MacBrains `codebase-memory-mcp` integration is installed and locally verified. Do not use Python. Preserve every existing repository and user change.

Target repository:

```text
https://github.com/naytewilson/codebase-memory-mcp
```

Preferred checkout:

```text
$HOME/Projects/codebase-memory-mcp
```

Execution contract:

1. Inspect the preferred checkout and any existing clone before changing anything. Record its Git root, branch, HEAD, dirty state, remotes, and worktrees. Do not reset, clean, stash, or overwrite user work.
2. If no clone exists, clone the repository to the preferred checkout. If a clean clone exists, fetch and fast-forward its current tracking branch. If it is dirty or diverged, preserve it and create an isolated worktree from the current `origin/main` instead of modifying the dirty checkout.
3. Read the root `AGENTS.md` and `docs/anvil/WORKFLOW.md` completely before installation.
4. Discover the real Git roots for the repositories currently used by ANVIL. Check likely locations such as `$HOME/ANVIL` and `$HOME/Projects/ane-re`, but pass only paths that actually exist and resolve with `git rev-parse --show-toplevel`. Do not scan or index every worktree.
5. Run `bash -n scripts/anvil-macos-bootstrap.sh`.
6. Run the bootstrap in release/UI mode, passing each selected active repository with a repeated `--project` argument. Do not use `curl | bash` directly; use the checked-out script so the MacBrains policy and receipt path are preserved.
7. Verify the installed binary with its absolute path, verify `codebase-memory-mcp cli list_projects`, inspect the generated receipt and indexed-root list, and verify that `~/Applications/Codebase Memory Graph.command` exists and is executable.
8. Open the Finder launcher or its localhost URL and verify that the UI responds. Capture the log path if startup fails.
9. Inspect the detected client configuration changes without printing secrets. Restarting open coding clients may require the user; label that as the only remaining boundary if local UI control is unavailable. After restart, verify that the MCP server is connected rather than assuming it.
10. Do not modify the CBM engine, ANVIL production behavior, Postgres, ledgers, manifests, or unrelated client settings during this installation.

Use the repository's native installer and exact bootstrap defaults:

```text
auto_index=false
auto_watch=false
```

Close with:

```text
PROVEN
MISSING EVIDENCE
POSSIBLY WRONG OR OVERSTATED
EXACT NEXT ACTION
WHAT DOES NOT COUNT AS COMPLETION
SAFE TO CONTINUE HERE OR START A FRESH CONTEXT
```

Include exact commands, exit codes, output excerpts, final Git state, and the receipt path. Do not call the setup complete until the installed binary, requested indexes, saved `list_projects` output, UI, and post-restart MCP connection are all observed.

---
