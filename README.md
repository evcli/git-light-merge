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

- **Git**: 2.0 or higher.
- **fzf** (Optional but **Highly Recommended**): Required for the best interactive experience with `git lm pick`. 
  - macOS: `brew install fzf`
  - Windows: `choco install fzf` or download the binary from [GitHub](https://github.com/junegunn/fzf/releases).
  - *Note: A native numbered list picker will be used as a fallback if `fzf` is not found.*

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

To remove `git-light-merge`:

1.  Run the uninstaller script in the repository root:
    ```bash
    ./uninstall.sh
    ```
2.  Remove the `source` or `zinit` line from your `.zshrc` or `.bashrc`.
3.  Delete the repository folder.

---

## 📖 Usage

### Core Workflow
- `git lm create|new|mk <name> <features...> [--base branch]` : Create a new task.
- `git lm add [feature] [name]` : Add a feature to a task. Use `.` for current branch.
- `git lm rm [feature] [name]` : Remove a feature from a task.
- `git lm status|st [name]` : Show the status and branches of a task.
- `git lm refresh|rf [name] [--base branch]` : Sync code and rebuild. Supports changing base.

> **💡 Pro Tip (Smart Selection)**: For commands like `status`, `refresh`, `add`, `push`, and `abort`, if you are not on a light-merge branch and don't provide a name, the tool will automatically select the target task if only one exists in your repo.

### Task Management
- `git lm list|ls` : List all local integration tasks.
- `git lm clear` : Delete ALL local integration tasks and state files.
- `git lm abort` : Stop and delete the current integration task.
- `git lm push` : Push the integration results to the remote repository.

### Utilities
- `git lm pick <name> [--base branch]` : Interactively pick features using `fzf`.
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

- `GIT_LM_USER`: User identifier for branch names (Default: system username).
- `GIT_LM_TEMPLATE`: Branch naming template (Default: `light-merge/{user}-{name}`).

---

## 🌟 Why Git Light Merge?

Unlike manual merging, `git-light-merge` manages complex merge states in the background. Even when integrating 10+ branches, you can easily adjust your environment via `add`, `rm`, or `refresh` without worrying about human error or losing track of your progress.
