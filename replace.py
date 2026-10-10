import re

with open('/home/alex/.claude/AGENTS.md', 'r') as f:
    content = f.read()

# Replace Staging, Merging, Scope Confirmation
content = re.sub(
    r'## Staging Discipline.*?## WSL Codex: HOME MUST BE /home/alex',
    '''## Core Workflows
- **Staging & Committing:** See [`guides/git-and-github-workflows.md`](guides/git-and-github-workflows.md#staging-discipline).
- **Merging & Teardown:** See [`guides/git-and-github-workflows.md`](guides/git-and-github-workflows.md). Run `gh pr merge` from primary checkout, never a worktree. `~/.Codex` merges aren't live until `git pull --ff-only`.
- **Scope Confirmation:** See [`rules/scope-confirmation.md`](rules/scope-confirmation.md) for rules on bulk operations and modifying multiple files.

## WSL Codex: HOME MUST BE /home/alex''',
    content, flags=re.DOTALL
)

# Replace WSL, Tooling Gotchas, Jev
content = re.sub(
    r'## WSL Codex: HOME MUST BE /home/alex.*?## Flagship Project Repos',
    '''## Environment & Gotchas
- **WSL Native Only:** `HOME` must be `/home/alex`. Any Windows path (`/mnt/c`) is a regression; stop and fix the launcher. Use Ubuntu tools (`apt`, `grep`), never PowerShell.
- **`settings.json` is clobbered mid-session:** Edit durably only when sessions are exited. See [`guides/session-discovered-gotchas.md`](guides/session-discovered-gotchas.md).
- **Tooling Traps:** See [`guides/cli-editing-gotchas.md`](guides/cli-editing-gotchas.md) for flag variants, YAML traps, etc.
- **Environment Gotchas:** See [`guides/session-discovered-gotchas.md`](guides/session-discovered-gotchas.md). Append new gotchas there.
- **Jev:** Use `~/.local/bin/jev` for probabilistic routing. Never install a same-named package. See [`guides/session-discovered-gotchas.md`](guides/session-discovered-gotchas.md).

## Flagship Project Repos''',
    content, flags=re.DOTALL
)

# Replace Flagship Project Repos table
content = re.sub(
    r'## Flagship Project Repos.*?## Secrets & Settings',
    '''## Flagship Project Repos
See [`README.md`](./README.md#5a-flagship-project-repos) for details on `ClaudeConfig`, `BotHaus`, `VistaMobileBE`, and `TradingBots`. All use SSH remotes: [`guides/git-and-github-workflows.md`](guides/git-and-github-workflows.md#ssh-remotes-not-https).

## Secrets & Settings''',
    content, flags=re.DOTALL
)

# Replace Secrets & Settings
content = re.sub(
    r'## Secrets & Settings \(`settings\.json` / `settings\.local\.json`\).*?## Skills',
    '''## Secrets & Settings (`settings.json` / `settings.local.json`)
- **`settings.json`:** Tracked config.
- **`settings.local.json`:** Gitignored. Secrets and local overrides only. Duplicate `GH_TOKEN` here since `.bashrc` isn't sourced.
- See [`README.md`](./README.md#4-restore-the-secrets--cannot-come-from-this-repo) and [`guides/session-discovered-gotchas.md`](guides/session-discovered-gotchas.md) for rotation and variables.

## Skills''',
    content, flags=re.DOTALL
)

with open('/home/alex/.claude/AGENTS.md', 'w') as f:
    f.write(content)
