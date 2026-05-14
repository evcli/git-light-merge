#!/usr/bin/env bash

# git-light-merge uninstaller
# This script removes the git alias and provides instructions for full cleanup.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { printf "${GREEN}[INFO]${NC} %b\n" "$*"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %b\n" "$*"; }
log_err()  { printf "${RED}[ERROR]${NC} %b\n" "$*"; }

echo "----------------------------------------"
echo "  git-light-merge Uninstaller"
echo "----------------------------------------"

# 1. Remove Git Alias
if git config --global --get alias.lm >/dev/null 2>&1; then
    log_info "Removing global git alias 'lm'..."
    git config --global --unset alias.lm
else
    log_warn "Git alias 'lm' not found. Skipping."
fi

echo ""
log_info "Uninstallation steps completed!"
echo "----------------------------------------"
log_warn "FINAL STEP (Manual):"
echo "Please remove the 'source' line from your .zshrc or .bashrc if it exists."
echo "----------------------------------------"
echo "Goodbye!"
