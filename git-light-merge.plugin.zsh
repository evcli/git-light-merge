# git-light-merge.plugin.zsh
# This plugin defines direct shell functions for instant git-light-merge execution.

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

# Ensure the script is executable and define shell helper functions
if [[ -f "$_LM_SCRIPT_EXEC" ]]; then
    [[ -x "$_LM_SCRIPT_EXEC" ]] || chmod +x "$_LM_SCRIPT_EXEC"
    
    # 1. Define glm function (direct execution, 0ms overhead)
    eval "glm() { \"${_LM_SCRIPT_EXEC}\" \"\$@\"; }"

    # 2. Define transparent git interceptor function (git lm interceptor, 0ms overhead)
    eval "git() {
        if [[ \"\$1\" == \"lm\" ]]; then
            shift
            \"${_LM_SCRIPT_EXEC}\" \"\$@\"
        else
            command git \"\$@\"
        fi
    }"
fi

# Cleanup local variables to avoid polluting the shell environment
unset _LM_PLUGIN_DIR
unset _LM_SCRIPT_EXEC
