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
    # Only chmod if not executable to save time
    [[ -x "$_LM_SCRIPT_EXEC" ]] || chmod +x "$_LM_SCRIPT_EXEC"
    
    # Only update git config if it's missing or points to a different location
    # This significantly speeds up shell startup
    if [[ "$(git config --global alias.lm 2>/dev/null)" != "!${_LM_SCRIPT_EXEC}" ]]; then
        git config --global alias.lm "!${_LM_SCRIPT_EXEC}"
    fi
fi

# Cleanup local variable to avoid polluting the shell environment
unset _LM_PLUGIN_DIR
unset _LM_SCRIPT_EXEC
