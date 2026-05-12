# Bash completion script for git-light-merge
# Works in Linux, macOS (Bash), and Windows Git Bash

_git_lm() {
    local cur prev words cword
    # Compatibility with different bash-completion versions
    if type _get_comp_words_by_ref &>/dev/null; then
        _get_comp_words_by_ref -n : cur prev words cword
    else
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
    fi

    local commands="add rm status list ls continue abort rebase refresh push pick clear prune help"
    
    # We are at the first argument after 'git lm' or 'git-light-merge'
    # For 'git lm', cword is 2. For 'git-light-merge', cword is 1.
    local cmd_index=1
    if [[ "${words[0]}" == "git" ]]; then
        cmd_index=2
    fi

    if [ $cword -eq $cmd_index ]; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        return 0
    fi

    # Handle subcommands that need branch names
    local subcmd="${words[$cmd_index]}"
    case "${subcmd}" in
        add|rm|pick)
            local branches=$(git branch --format='%(refname:short)' 2>/dev/null)
            COMPREPLY=( $(compgen -W "${branches}" -- ${cur}) )
            return 0
            ;;
    esac
}

# Register for both forms
complete -F _git_lm git-light-merge

# For Git Bash, try to register it as a git subcommand completion
if type __git_complete &>/dev/null; then
    __git_complete git lm _git_lm
else
    # Fallback for simple git alias completion
    complete -F _git_lm git
fi
