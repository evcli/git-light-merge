#!/usr/bin/env bash

set -e

# Define colors
RED='\033[0;31m'
NC='\033[0m'

# Determine target directory based on OS
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    TARGET_DIR="$HOME/bin"
else
    TARGET_DIR="$HOME/.local/bin"
fi

if [[ -f "$TARGET_DIR/git-light-merge" ]]; then
    printf "${RED}Removing git-light-merge from $TARGET_DIR...${NC}\n"
    rm "$TARGET_DIR/git-light-merge"
    printf "Removing git alias...\n"
    git config --global --unset alias.lm || true
    printf "Done.\n"
else
    echo "git-light-merge is not found in $TARGET_DIR"
fi
