#!/usr/bin/env bash

set -e

# Define colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'

printf "${BLUE}Installing git-light-merge...${NC}\n"

# Determine target directory based on OS
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows Git Bash
    TARGET_DIR="$HOME/bin"
    SHELL_CONFIG="$HOME/.bashrc"
else
    # Mac or Linux
    TARGET_DIR="$HOME/.local/bin"
    # Detect shell config file
    if [[ "$SHELL" == */zsh* ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    else
        SHELL_CONFIG="$HOME/.bashrc"
    fi
fi

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

echo "Copying script to $TARGET_DIR"
cp bin/git-light-merge "$TARGET_DIR/git-light-merge"
chmod +x "$TARGET_DIR/git-light-merge"

# Check if TARGET_DIR is in PATH
if [[ ":$PATH:" != *":$TARGET_DIR:"* ]]; then
    printf "\n${YELLOW}Checking PATH environment...${NC}\n"
    printf "${YELLOW}Warning: $TARGET_DIR is not in your PATH.${NC}\n"
    printf "To use git-light-merge from anywhere, add it to your config:\n"
    printf "\n"
    printf "${BLUE}  echo 'export PATH=\"$TARGET_DIR:\$PATH\"' >> $SHELL_CONFIG${NC}\n"
    printf "${BLUE}  source $SHELL_CONFIG${NC}\n"
    printf "\n"
else
    printf "\n${GREEN}Installation successful!${NC}\n"
    printf "Configuring git alias...\n"
    git config --global alias.lm light-merge
    printf "You can now use ${BLUE}git light-merge${NC} or ${BLUE}git lm${NC}\n"
fi
