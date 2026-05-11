#!/usr/bin/env bash

_git_lm_bash() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Subcommands
    opts="add rm status continue abort rebase push pick prune help"

    if [[ ${COMP_CWORD} -eq 2 ]]; then
        # Complete subcommands
        COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
        return 0
    fi

    case "${prev}" in
        add|rm|pick|--base)
            # Complete branches
            local branches=$(git branch --format='%(refname:short)')
            COMPREPLY=( $(compgen -W "${branches}" -- ${cur}) )
            return 0
            ;;
        *)
            # For the main create command, also suggest branches
            if [[ ${COMP_CWORD} -ge 3 ]]; then
                 local branches=$(git branch --format='%(refname:short)')
                 COMPREPLY=( $(compgen -W "${branches}" -- ${cur}) )
            fi
            ;;
    esac
}

# Register for both names
complete -F _git_lm_bash git-lm
complete -F _git_lm_bash git-light-merge
