# MacBrains ANVIL Agent Contract

This fork carries a MacBrains integration overlay for `codebase-memory-mcp`. The upstream engine remains a derived structural-code index. It is not the canonical source of repository state, ANVIL decisions, receipts, or experiment results.

## Authority order

Use the first available source in this order:

1. Current Git worktree, branch, HEAD, tracked instructions, source, and tests.
2. Canonical ANVIL Postgres records, ledgers, manifests, and accepted receipts when the task is part of ANVIL.
3. Current build, test, benchmark, and runtime output.
4. `codebase-memory-mcp` graph results, coverage reports, and impact analysis.
5. Handoffs and conversation narrative.

A graph result is evidence for where to inspect. It never overrides contradictory source or canonical ANVIL state.

## Required startup sequence

Before planning, editing, reviewing, debugging, or reporting:

1. Establish the exact repository and worktree:
   ```bash
   git rev-parse --show-toplevel
   git status --short --branch
   git rev-parse HEAD
   git worktree list --porcelain
   ```
2. Read the applicable `AGENTS.md`, project instructions, canonical docs, manifests, and recent receipts.
3. Emit or record the required ANVIL `source_truth_preflight` event when operating through ANVIL.
4. Select the canonical worktree. Never let a graph project name choose a worktree.
5. Confirm that the graph project resolves to the same physical root with `pwd -P` or `realpath`.
6. Use the graph for narrow discovery, then verify every material claim in source.

Do not begin with a broad graph query and treat its output as a repository inventory.

## Graph operating policy

### Default tier: Verify

Use the installed Verify profile for ordinary work:

- narrow `search_graph` queries;
- task-relevant inbound and outbound `trace_path` calls;
- exact `get_code_snippet` evidence for material symbols;
- one batched `check_index_coverage` call for every cited path;
- source read or grep fallback for any partial, stale, skipped, excluded, pending, or unknown coverage.

Scout is provisional discovery only. Auditor requires a bounded scope, current generation, complete relevant pagination, and source fallback for every coverage gap.

### Negative and exhaustive claims

Do not claim that code is absent, dead, unused, complete, or unaffected unless all of the following are present:

- the exact project and current generation;
- relevant path and scope coverage;
- complete pagination inside a stated bounded scope;
- source fallback for every coverage gap;
- current Git diff and worktree state.

A clean graph result means no recorded graph gap. It does not prove repository completeness.

### Allowed mutations

During normal repository work, graph access is read-only. Do not call `manage_adr`, `delete_project`, graph import/export mutation, or configuration mutation.

Explicit indexing is allowed only for the exact active repository or worktree after source-truth preflight. Use the documented native command:

```bash
codebase-memory-mcp cli --progress index_repository --repo-path "$(git rev-parse --show-toplevel)"
```

`auto_index` and `auto_watch` remain disabled by the MacBrains bootstrap. This prevents accidental indexing of dozens of APFS worktrees and keeps resource use predictable on the Neo Mac.

## ANVIL integration boundary

`codebase-memory-mcp` supplies structural code intelligence only:

- symbols, definitions, types, calls, imports, routes, and graph relationships;
- targeted source snippets and coverage status;
- change-impact candidates.

ANVIL remains responsible for:

- task selection and ownership;
- canonical Postgres and ledger writes;
- worktree allocation and collision prevention;
- artifact retrieval and large-document evidence;
- execution, resource admission, tests, reviews, integration, and receipts.

Never write CBM-derived conclusions directly into canonical state without source verification. Never treat a CBM ADR as an ANVIL decision record.

## Worktree policy

Use an isolated worktree when work can overlap another task. Index the exact active worktree, not a parent directory and not every sibling worktree. Re-index after switching to a materially different branch or worktree.

Do not delete or rewrite another agent's worktree, branch, index, receipt, or uncommitted changes.

## Edit and verification sequence

1. Source-truth preflight.
2. Narrow graph discovery and coverage check.
3. Direct source inspection.
4. Smallest safe edit.
5. Targeted test or reproduction.
6. Canonical broader test, lint, and security checks supported by the repository.
7. `detect_changes` for impact candidates, followed by direct source verification.
8. Final diff, staged-file list, repository state, and ANVIL receipt.

For this repository, the canonical gates are:

```bash
scripts/test.sh
scripts/lint.sh
make -f Makefile.cbm security
```

Do not claim these passed unless their current command output was observed.

## Platform rules

- Neo Mac is the canonical control plane.
- The Dell node is compute-only. A node-local graph is disposable and cannot write canonical ANVIL Postgres state.
- Use C, Swift, or shell for durable implementation. Do not add Python to the Linux compute path.
- Keep the default shared CBM cache root unless every client is migrated together; mixed cache roots are rejected by the coordination barrier.

## Installation

On macOS, use:

```bash
bash scripts/anvil-macos-bootstrap.sh --project /absolute/path/to/active/repository
```

The bootstrap installs the UI build by default, configures detected MCP clients through the native installer, disables automatic indexing and watchers, creates a Finder-launchable graph UI command, explicitly indexes only supplied project roots, and writes a local receipt.

## Completion receipt

Close every task with these exact evidence classes:

- `PROVEN`
- `MISSING EVIDENCE`
- `POSSIBLY WRONG OR OVERSTATED`
- `EXACT NEXT ACTION`
- `WHAT DOES NOT COUNT AS COMPLETION`
- `SAFE TO CONTINUE HERE OR START A FRESH CONTEXT`
