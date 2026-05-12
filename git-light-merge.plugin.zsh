# git-light-merge.plugin.zsh
# This plugin automatically configures the 'git lm' alias to point to the script's absolute path.

# Get the absolute path of the directory containing this plugin file
# Support both Zsh and Bash sourcing
if [[ -n "$ZSH_VERSION" ]]; then
    _LM_PLUGIN_DIR="${0:h}"
elif [[ -n "$BASH_VERSION" ]]; then
    _LM_PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    _LM_PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

_LM_SCRIPT_EXEC="${_LM_PLUGIN_DIR}/bin/git-light-merge"

# Ensure the script is executable
if [[ -f "$_LM_SCRIPT_EXEC" ]]; then
    chmod +x "$_LM_SCRIPT_EXEC"
    
    # Configure git alias to point to the absolute path
    # We use '!' to tell git it's an external command
    git config --global alias.lm "!${_LM_SCRIPT_EXEC}"
fi

# Load completions
if [[ -n "$ZSH_VERSION" ]]; then
    # For Zsh, add to fpath. Zinit or compinit will handle the rest.
    fpath=("${_LM_PLUGIN_DIR}/completions" $fpath)
elif [[ -n "$BASH_VERSION" ]]; then
    # For Bash (including Git Bash on Windows), source the script directly.
    if [[ -f "${_LM_PLUGIN_DIR}/completions/git-lm.bash" ]]; then
        source "${_LM_PLUGIN_DIR}/completions/git-lm.bash"
    fi
fi

# Cleanup local variable to avoid polluting the shell environment
unset _LM_PLUGIN_DIR
unset _LM_SCRIPT_EXEC
