#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GIT_LM="$PROJECT_ROOT/bin/git-light-merge"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

fail() {
	printf "FAIL: %s\n" "$*" >&2
	exit 1
}

assert_grep() {
	local pattern="$1"
	local file="$2"
	if ! grep -q -- "$pattern" "$file"; then
		printf "Expected pattern not found: %s\n" "$pattern" >&2
		printf "--- %s ---\n" "$file" >&2
		cat "$file" >&2
		fail "assert_grep failed"
	fi
}

assert_not_grep() {
	local pattern="$1"
	local file="$2"
	if grep -q -- "$pattern" "$file"; then
		printf "Unexpected pattern found: %s\n" "$pattern" >&2
		printf "--- %s ---\n" "$file" >&2
		cat "$file" >&2
		fail "assert_not_grep failed"
	fi
}

init_repo() {
	local repo="$1"
	git init -q "$repo"
	cd "$repo"
	git config user.email test@example.com
	git config user.name Tester
	printf "base\n" > file.txt
	git add file.txt
	git commit -q -m init
	git branch -M main
}

add_feature_branch() {
	local branch="$1"
	local file_name="${branch//\//_}.txt"
	git checkout -q main
	git checkout -q -b "$branch"
	printf "%s\n" "$branch" > "$file_name"
	git add "$file_name"
	git commit -q -m "$branch"
	git checkout -q main
}

add_origin() {
	local origin="$1"
	git init --bare -q "$origin"
	git remote add origin "$origin"
	git push -q -u origin main
}

test_syntax() {
	printf "Running syntax tests...\n"
	bash -n "$GIT_LM"
	bash -n "$PROJECT_ROOT/bin/git-lm-picker"
	bash -n "$PROJECT_ROOT/git-light-merge.plugin.zsh"
	printf "syntax tests passed.\n"
}

test_create() {
	printf "Running create tests...\n"

	local repo="$TMP_ROOT/create-work"
	local origin="$TMP_ROOT/create-origin.git"
	init_repo "$repo"
	add_origin "$origin"
	add_feature_branch "feature/a"
	git push -q origin feature/a

	"$GIT_LM" create demo feature/a --base main > "$TMP_ROOT/create.out" 2>&1
	assert_grep "Success" "$TMP_ROOT/create.out"

	if "$GIT_LM" create bad feature/a --base > "$TMP_ROOT/base-missing.out" 2>&1; then
		fail "--base without value unexpectedly succeeded"
	fi
	assert_grep "Error: --base requires a branch name." "$TMP_ROOT/base-missing.out"
	assert_not_grep "unbound variable" "$TMP_ROOT/base-missing.out"

	add_feature_branch "feature/local-only"
	if "$GIT_LM" create localonly feature/local-only --base main > "$TMP_ROOT/local-only.out" 2>&1; then
		fail "local-only feature unexpectedly succeeded"
	fi
	assert_grep "Error: Feature 'feature/local-only' is local-only" "$TMP_ROOT/local-only.out"

	printf "create tests passed.\n"
}

test_status() {
	printf "Running status tests...\n"

	local repo="$TMP_ROOT/status-work"
	local origin="$TMP_ROOT/status-origin.git"
	init_repo "$repo"
	add_origin "$origin"
	add_feature_branch "feature/a"
	git push -q origin feature/a

	"$GIT_LM" create demo feature/a --base main > "$TMP_ROOT/status-create.out" 2>&1
	"$GIT_LM" status demo > "$TMP_ROOT/status.out" 2>&1
	assert_grep "Branch  : .*light-merge/demo" "$TMP_ROOT/status.out"
	assert_grep "Base    : .*main" "$TMP_ROOT/status.out"
	assert_grep "Features: .*feature/a" "$TMP_ROOT/status.out"

	printf "status tests passed.\n"
}

test_sync() {
	printf "Running sync tests...\n"

	local origin="$TMP_ROOT/sync-origin.git"
	local repo="$TMP_ROOT/sync-work"
	init_repo "$repo"
	add_origin "$origin"
	add_feature_branch "feature/a"
	git push -q origin feature/a

	"$GIT_LM" create demo feature/a --base main > "$TMP_ROOT/sync-create.out" 2>&1
	"$GIT_LM" sync demo > "$TMP_ROOT/sync-local-only.out" 2>&1
	assert_grep "local-only" "$TMP_ROOT/sync-local-only.out"

	git fetch -q origin
	"$GIT_LM" sync demo > "$TMP_ROOT/sync-up-to-date.out" 2>&1
	assert_grep "already in sync" "$TMP_ROOT/sync-up-to-date.out"

	printf "sync tests passed.\n"
}

test_refresh() {
	printf "Running refresh tests...\n"

	local origin="$TMP_ROOT/refresh-origin.git"
	local repo="$TMP_ROOT/refresh-work"
	init_repo "$repo"
	add_origin "$origin"
	add_feature_branch "feature/a"
	git push -q origin feature/a

	"$GIT_LM" create demo feature/a --base main > "$TMP_ROOT/refresh-create.out" 2>&1
	git remote set-url origin "$TMP_ROOT/missing-origin.git"

	"$GIT_LM" refresh demo > "$TMP_ROOT/refresh-warning.out" 2>&1
	assert_grep "Could not fetch base 'main' from origin" "$TMP_ROOT/refresh-warning.out"
	assert_grep "Could not batch fetch feature branches from origin" "$TMP_ROOT/refresh-warning.out"
	assert_grep "Success" "$TMP_ROOT/refresh-warning.out"

	printf "refresh tests passed.\n"
}

test_pick() {
	printf "Running pick tests...\n"

	local repo="$TMP_ROOT/pick-work"
	local origin="$TMP_ROOT/pick-origin.git"
	init_repo "$repo"
	add_origin "$origin"
	add_feature_branch "feature/a"
	git push -q origin feature/a
	add_feature_branch "feature/b"

	"$GIT_LM" create demo feature/a --base main > "$TMP_ROOT/pick-create.out" 2>&1
	printf '\n' | GIT_LM_PICKER_PLUGIN="$TMP_ROOT/missing-picker" "$GIT_LM" pick demo --base main > "$TMP_ROOT/pick-fallback.out" 2>&1

	assert_grep "\[x\] feature/a" "$TMP_ROOT/pick-fallback.out"
	assert_grep "feature/b \[local only\]" "$TMP_ROOT/pick-fallback.out"
	assert_grep "Local-only branches are shown for visibility but cannot be selected" "$TMP_ROOT/pick-fallback.out"
	assert_grep "Enter to keep checked" "$TMP_ROOT/pick-fallback.out"
	assert_grep "Selected features: feature/a" "$TMP_ROOT/pick-fallback.out"
	assert_grep "Success" "$TMP_ROOT/pick-fallback.out"

	printf "pick tests passed.\n"
}

usage() {
	cat <<EOF
Usage: scripts/smoke-test.sh [all|syntax|create|status|sync|refresh|pick]...

Examples:
  scripts/smoke-test.sh              # run all tests
  scripts/smoke-test.sh sync         # run only sync tests
  scripts/smoke-test.sh status sync  # run status and sync tests
EOF
}

run_suite() {
	case "$1" in
		all)
			test_syntax
			test_create
			test_status
			test_sync
			test_refresh
			test_pick
			;;
		syntax) test_syntax ;;
		create) test_create ;;
		status) test_status ;;
		sync) test_sync ;;
		refresh) test_refresh ;;
		pick) test_pick ;;
		help|--help|-h) usage ;;
		*)
			usage >&2
			fail "unknown test target: $1"
			;;
	esac
}

main() {
	local targets=("$@")
	if [[ ${#targets[@]} -eq 0 ]]; then
		targets=(all)
	fi

	printf "Running git-light-merge smoke tests: %s\n" "${targets[*]}"

	local target
	for target in "${targets[@]}"; do
		run_suite "$target"
	done

	printf "Smoke tests passed: %s\n" "${targets[*]}"
}

main "$@"