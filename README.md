# git-light-merge (git lm)

A professional Git CLI tool to automate and atomize merging multiple feature branches into a single, clean light-merge branch.

## Key Features

- **Single Squash Commit**: Maintains only one commit relative to the base branch. All feature merge history is squashed for a clean integration view.
- **Resumable Workflow (`continue`)**: If conflicts occur, resolve them and resume exactly where you left off. No need to restart the entire process.
- **Stateful Management**: Remembers which branches are merged. Easily `add` or `rm` features and let the tool rebuild the branch for you.
- **Interactive Picker (`pick`)**: Select branches using a fuzzy finder (`fzf`) or a native numbered list (no dependencies required).
- **Cross-Platform**: Fully compatible with **macOS** and **Windows Git Bash**.
- **On-demand Sync**: `rebase` command automatically fetches the latest base branch and rebuilds everything.
- **Smart Pushing**: `push` command bypasses force-push restrictions by performing a delete-then-push sequence.

---

## Installation

### 1. Run Install Script
```bash
bash install.sh
```
This script copies the tool to your local bin directory and configures the `git lm` alias.

### 2. Setup Auto-completion (Highly Recommended)

#### For macOS (Zsh)
Add the following to your `~/.zshrc`:
```zsh
fpath=(/path/to/git-light-merge/completions $fpath)
autoload -Uz compinit && compinit
```

#### For Windows / Git Bash (Bash)
Add the following to your `~/.bashrc`:
```bash
source /path/to/git-light-merge/completions/git-lm.bash
```

---

## Command Reference

| Command | Description |
| :--- | :--- |
| `git lm <name> <f1> <f2>...` | Create a new light-merge branch and merge features. |
| `git lm pick <name>` | Interactively pick features from a list. |
| `git lm add <feature>` | Add a new feature to the current branch and rebuild. |
| `git lm rm <feature>` | Remove a feature from the current branch and rebuild. |
| `git lm continue` | Resume the merge loop after resolving conflicts. |
| `git lm status` | Show current branch status and merged features. |
| `git lm rebase` | Fetch latest base branch and rebuild the entire branch. |
| `git lm push` | Push to remote (Safe delete + Push). |
| `git lm abort` | Delete current light-merge branch and cleanup state. |
| `git lm prune` | Cleanup old/orphaned state files. |

### Options
- `--base <branch>`: Specify a base branch (Default: `git default-branch` or `main`).

---

## Configuration

You can customize the tool via environment variables or by editing the top of `bin/git-light-merge`:

- `GIT_LM_USER`: User identifier for branch names (Default: system username).
- `GIT_LM_TEMPLATE`: Branch naming template. Default: `light-merge/{user}-{name}`.

