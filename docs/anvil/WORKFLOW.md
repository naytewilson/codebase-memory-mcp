# codebase-memory-mcp in the MacBrains ANVIL workflow

## Decision

Use `codebase-memory-mcp` as the **derived structural-code intelligence layer** beneath ANVIL. Do not use it as a second canonical memory system.

This division avoids the failure mode where a fast but stale graph silently competes with Git, ANVIL Postgres, the experiment ledger, or accepted receipts.

| Layer | Role | Authority |
|---|---|---|
| Git worktree and tracked instructions | Current implementation and repository policy | Canonical |
| ANVIL Postgres, ledger, manifests, accepted receipts | Durable task, decision, experiment, and integration state | Canonical |
| ANVIL Artifact Retrieval Core | Large-artifact and document retrieval | Evidence service |
| codebase-memory-mcp | Symbols, calls, types, routes, graph traversal, source snippets, coverage, impact candidates | Derived evidence |
| Conversation or handoff | Intent and leads | Non-canonical |

## Why this fit is correct

The tool is a pure C local binary, has no API-key or Docker dependency, supports macOS and Linux, exposes structural graph tools, and installs read-only Scout/Verify/Auditor profiles for supported agents. Its native installer already coordinates one per-account daemon and configures detected clients. Replacing those mechanisms would create a private fork that is harder to update and less tested.

The MacBrains overlay therefore changes **policy and installation**, not the engine:

- keep upstream release binaries and security verification by default;
- use the UI build so the backend has a visible Finder launch path;
- disable automatic indexing and watchers;
- index only exact active worktrees;
- require source-truth preflight before graph use;
- make Verify the normal tier;
- prohibit graph-derived writes to canonical ANVIL state;
- preserve native tests, lint, security gates, and upstream updateability.

## Neo Mac resource policy

The Neo Mac is the canonical control plane and has a tight memory budget. ANVIL also uses many APFS worktrees. The safe defaults are:

```text
auto_index=false
auto_watch=false
```

This prevents every newly visited worktree from becoming a background graph project. Explicit indexing is faster to reason about and makes ownership visible.

Keep the default shared cache root unless every client is migrated in one maintenance action. The CBM coordination barrier requires all active processes to agree on the exact build, coordination ABI, and canonical cache root.

Index the exact worktree used for the task:

```bash
codebase-memory-mcp cli --progress index_repository \
  --repo-path "$(git rev-parse --show-toplevel)"
```

Do not index a directory that merely contains several repositories or sibling worktrees.

## Install on the Mac

Clone or update this fork, then run the bootstrap with each repository that should be immediately available:

```bash
git clone https://github.com/naytewilson/codebase-memory-mcp.git \
  "$HOME/Projects/codebase-memory-mcp"

cd "$HOME/Projects/codebase-memory-mcp"

bash scripts/anvil-macos-bootstrap.sh \
  --project "$HOME/ANVIL" \
  --project "$HOME/Projects/ane-re"
```

Pass only paths that exist. The script resolves each argument to its physical Git root, rejects non-repositories, de-duplicates roots, and indexes them sequentially.

The default `--release` mode runs the repository's checksum-verifying installer and receives the current upstream release. Use `--source` only when intentionally testing changes in this checkout:

```bash
bash scripts/anvil-macos-bootstrap.sh --source --project "$PWD"
```

The source path uses the repository's canonical `scripts/build.sh`; it does not invent a separate build pipeline.

## What the bootstrap changes

The bootstrap performs these explicit mutations:

1. Installs the UI or standard native binary into `~/.local/bin` unless another directory is supplied.
2. Lets the native installer configure detected MCP clients and its durable read-only profiles and hooks.
3. Sets `auto_index=false` and `auto_watch=false`.
4. Adds one marked PATH line to `.zprofile` only when the install directory is absent from the current PATH.
5. Creates `~/Applications/Codebase Memory Graph.command` for the UI build.
6. Indexes only `--project` roots.
7. Writes a local receipt under `~/.local/state/macbrains/codebase-memory-mcp/`.

Use `--dry-run` to inspect commands, `--no-index` to install without graph creation, `--headless` to omit the UI build, or `--no-launcher` to omit the Finder command.

## Agent execution path

### 1. Source truth

Before CBM use, establish the current repository, branch, HEAD, dirty state, worktrees, instructions, canonical ANVIL records, and task ownership.

### 2. Exact graph project

Confirm that the indexed root and active Git root are the same physical directory. Re-index after moving to a materially different worktree or branch.

### 3. Verify-tier discovery

Use narrow structural queries to identify candidates. Trace only task-relevant relationships. Fetch exact snippets for material symbols. Batch all cited paths into one coverage check.

### 4. Source verification

Read the real files before proposing or applying a change. For missing or partial coverage, use direct source search on the reported ranges or scope.

### 5. Edit and validate

Make the smallest safe edit in the correct isolated worktree. Run the repository's targeted test, broader test, lint, and security checks. Use graph impact analysis as a review aid, not a test substitute.

### 6. Canonical receipt

Record only source-verified conclusions, commands, outputs, diffs, and test evidence in ANVIL. A CBM query result alone is not acceptable receipt evidence for completion.

## Retrieval routing

Use the smallest correct retrieval surface:

- **CBM:** symbol discovery, call paths, type relationships, routes, structural impact.
- **Artifact Retrieval Core:** large Markdown, PDFs, logs, reports, and distant text sections.
- **Git/source tools:** exact implementation, configuration, generated files, and current diff.
- **ANVIL Postgres/ledger:** accepted decisions, task state, ownership, and experiment truth.

Do not send large documents through CBM merely because they are in the repository. Do not ask Artifact Retrieval Core to reconstruct a call graph that CBM already indexes.

## Dell node boundary

The Dell node may install the headless binary for local compute-repository analysis, but its graph remains disposable. The node cannot write canonical Postgres state. Results become canonical only when a Mac-side ANVIL process verifies source and ingests a receipt.

Do not share a live cache directory across Neo and the Dell over the network. Build separate machine-local indexes from the same Git commit and compare receipts when needed.

## Visibility and troubleshooting

Open the generated Finder command:

```text
~/Applications/Codebase Memory Graph.command
```

It starts the UI build if necessary, writes logs to:

```text
~/Library/Logs/MacBrains/codebase-memory-mcp-ui.log
```

and opens:

```text
http://127.0.0.1:9749
```

Bootstrap evidence is stored at:

```text
~/.local/state/macbrains/codebase-memory-mcp/last-bootstrap.md
~/.local/state/macbrains/codebase-memory-mcp/projects.json
~/.local/state/macbrains/codebase-memory-mcp/indexed-roots.txt
```

If a client cannot connect, first restart it, then verify the installed binary and receipt. Do not delete configs or graph data before reading the daemon and activation logs under the native cache root.

## Upstream maintenance

Keep the engine close to upstream. This overlay intentionally adds new files instead of rewriting engine internals or the upstream README.

```bash
git remote add upstream https://github.com/DeusData/codebase-memory-mcp.git
git fetch upstream
git switch main
git merge upstream/main
git push origin main
```

Resolve an upstream conflict only from current files and tests. Do not discard the MacBrains overlay or force-reset the fork merely to make the branch look identical.

## Completion standard

Installation is complete only when all of these are observed:

- installed binary executes and reports a version;
- the two explicit-index configuration writes succeed;
- every requested project index command succeeds;
- `list_projects` succeeds and its output is saved;
- the local receipt exists;
- after a client restart, the MCP server is visibly connected.

A successful download, a generated config file, an unverified graph query, or a statement that the client "should" reconnect does not count as completion.
