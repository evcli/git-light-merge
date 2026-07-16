# Git Light Merge (git lm)

A powerful and lightweight Git automation tool designed to integrate multiple feature branches into a temporary integration branch (light-merge) with a single command.

## 🚀 Key Features

- **One-Command Integration**: Merge multiple branches into a target branch with automatic squashing.
- **State Persistence**: Automatically saves progress when conflicts occur; resume using `git lm continue`.
- **Multi-Task Support**: Manage multiple different integration tasks simultaneously.
- **Auto-Sync (Refresh)**: Fetch the latest base and features from origin and rebuild the integration environment in one click. Supports changing base branch on the fly.
- **Cross-Platform**: Seamlessly works on macOS (Zsh/Bash) and Windows (Git Bash).

---

## 📋 Prerequisites

- **Bash**: 5.0 or higher (Optimized for Bash 5.x, no compatibility wrappers for obsolete versions).
- **Git**: 2.0 or higher.
- **Interactive TUI Support** (Built-in!): An interactive selection menu is built-in (`git-lm-picker`) for selecting tasks and features seamlessly.
  - *Note: A native numbered list picker will be used as a fallback if the picker plugin is not found or executed in a non-interactive shell.*

---

## 🛠️ Installation

### 1. macOS (Using Zsh Plugin Managers)

We recommend using **Zinit** or other plugin managers for a zero-configuration experience:

```zsh
# Add to your .zshrc
zinit light evcli/git-light-merge
```

Or manually source it:
```zsh
# After cloning the repo, add to your .zshrc
source /path/to/git-light-merge/git-light-merge.plugin.zsh
```

### 2. Windows (Git Bash)

Include the plugin in your `.bashrc` in the Git Bash environment:

1.  Open Git Bash and edit or create `~/.bashrc`:
    ```bash
    notepad ~/.bashrc
    ```
2.  Add the following line:
    ```bash
    source /c/path/to/git-light-merge/git-light-merge.plugin.zsh
    ```
3.  Restart Git Bash or run `source ~/.bashrc`.

---

## 🗑️ Uninstallation

To remove `git-light-merge` completely:

1.  Remove the `source` or `zinit` line from your `.zshrc` or `.bashrc`.
2.  Delete the repository folder.

---

## 📖 Usage

> **Shared Task Rule**: Feature branches used in a light-merge task must exist on `origin` first. Local-only branches are shown in `git lm pick` for visibility, but they cannot be merged until they are pushed to `origin`. This keeps generated light-merge tasks refreshable and shareable by teammates.

### Core Workflow
- `git lm create|new|mk <name> <features...> [--base branch]` : Create a new task.
- `git lm add [feature] [name]` : Add a feature to a task. Use `.` for current branch.
- `git lm rm [feature] [name]` : Remove a feature from a task.
- `git lm status|st [name]` : Show the status and branches of a task.
- `git lm refresh|rf [name] [--base branch]` : Sync code and rebuild. Supports changing base.

> **💡 Pro Tip (Smart Selection)**: For commands like `status`, `refresh`, `add`, `push`, and `abort`, if you are not on a light-merge branch and don't provide a name, the tool will automatically select the target task if only one exists in your repo.

### Task Management
- `git lm list|ls` : List all integration tasks, labeled with type tags: `(L)` (local-only), `(R)` (remote-only), or `(L+R)` (local & remote). For each task, detailed commit info (time and author), base branch, and feature branches are printed in a clean, aligned, and indented layout.
- `git lm clear` : Delete ALL local integration tasks and state files.
- `git lm abort` : Stop and delete the current integration task.
- `git lm push` : Push the integration results to origin. For environments where forced pushes are blocked, this command first deletes the remote branch on origin and then pushes the new local generated branch.
- `git lm pull` : Pull a remote integration task to local, overriding the local generated branch.
- `git lm sync` : Sync local and remote integration tasks. If both exist and point to different commits, the newest generated commit wins; if the timestamps are identical, the command refuses to guess and asks you to choose `push` or `pull` explicitly.

### Utilities
- `git lm pick <name> [--base branch]` : Interactively pick features using a beautiful TUI selection menu.
- `git lm continue|con` : Resume the merging process after resolving conflicts.
- `git lm prune` : Clean up orphaned temporary state directories.

---

## ⚠️ Handling Conflicts

When a conflict occurs during merging:

1.  The script stops and saves the current progress.
2.  Manually resolve the conflicts in the affected files.
3.  Run `git add .`.
4.  Run `git commit -m "fix conflict"` (the message will be squashed later).
5.  Run **`git lm continue`** (or `git lm con`) to resume the merging process.

---

## ⚙️ Configuration

Customize the tool via environment variables:

- `GIT_LM_TEMPLATE`: Branch naming template (Default: `light-merge/{name}`).

---

## 🧪 Development / Testing

Run the full smoke test suite from the project root:

```bash
scripts/smoke-test.sh
```

You can also run only the tests related to the command you changed by passing one or more test targets:

```bash
scripts/smoke-test.sh sync
scripts/smoke-test.sh status sync
scripts/smoke-test.sh syntax create status sync refresh pick
```

Available targets: `all`, `syntax`, `create`, `status`, `sync`, `refresh`, and `pick`. Running without arguments is the same as `all`.

The smoke script creates temporary Git repositories and verifies core workflows such as `create`, `status`, `sync`, `refresh`, and native `pick` fallback behavior. It requires Bash 5.0+ and Git.

---

## 🌟 Why Git Light Merge?

Unlike manual merging, `git-light-merge` manages complex merge states in the background. Even when integrating 10+ branches, you can easily adjust your environment via `add`, `rm`, or `refresh` without worrying about human error or losing track of your progress.
