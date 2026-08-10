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
		printf "%s\n" "--- $file ---" >&2
		cat "$file" >&2
		fail "assert_grep failed"
	fi
}

assert_not_grep() {
	local pattern="$1"
	local file="$2"
	if grep -q -- "$pattern" "$file"; then
		printf "Unexpected pattern found: %s\n" "$pattern" >&2
		printf "%s\n" "--- $file ---" >&2
		cat "$file" >&2
		fail "assert_not_grep failed"
	fi
}

assert_line_order() {
	local first_pattern="$1"
	local second_pattern="$2"
	local file="$3"
	local first_line=""
	local second_line=""

	first_line=$(grep -n -- "$first_pattern" "$file" | head -n 1 | cut -d: -f1 || true)
	second_line=$(grep -n -- "$second_pattern" "$file" | head -n 1 | cut -d: -f1 || true)

	if [[ -z "$first_line" || -z "$second_line" || "$first_line" -ge "$second_line" ]]; then
		printf "Expected '%s' to appear before '%s' in %s\n" "$first_pattern" "$second_pattern" "$file" >&2
		cat "$file" >&2
		fail "assert_line_order failed"
	fi
}

assert_line_count() {
	local expected="$1"
	local pattern="$2"
	local file="$3"
	local actual

	actual=$(grep -c -- "$pattern" "$file" || true)
	if [[ "$actual" -ne "$expected" ]]; then
		printf "Expected %s occurrence(s) of '%s' in %s, got %s\n" "$expected" "$pattern" "$file" "$actual" >&2
		cat "$file" >&2
		fail "assert_line_count failed"
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

	"$GIT_LM" push demo > "$TMP_ROOT/status-initial-push.out" 2>&1
	assert_grep "Summary" "$TMP_ROOT/status-initial-push.out"

	git push -q origin --delete feature/a
	git fetch -q origin --prune
	local red_feature
	red_feature=$(printf '\033\\[31mfeature/a')

	"$GIT_LM" status demo > "$TMP_ROOT/status-missing-remote.out" 2>&1
	assert_grep "Features: .*feature/a" "$TMP_ROOT/status-missing-remote.out"
	assert_grep "missing on origin: feature/a" "$TMP_ROOT/status-missing-remote.out"
	assert_not_grep "Task 'light-merge/demo'" "$TMP_ROOT/status-missing-remote.out"
	assert_grep "$red_feature" "$TMP_ROOT/status-missing-remote.out"

	"$GIT_LM" list > "$TMP_ROOT/list-missing-remote.out" 2>&1
	assert_grep "light-merge/demo" "$TMP_ROOT/list-missing-remote.out"
	assert_grep "light-merge/demo.*synced:" "$TMP_ROOT/list-missing-remote.out"
	assert_grep "missing on origin: feature/a" "$TMP_ROOT/list-missing-remote.out"
	assert_not_grep "Task 'light-merge/demo'" "$TMP_ROOT/list-missing-remote.out"
	assert_grep "$red_feature" "$TMP_ROOT/list-missing-remote.out"

	if "$GIT_LM" push demo > "$TMP_ROOT/push-missing-local.out" 2>&1; then
		fail "push with missing local feature unexpectedly succeeded"
	fi
	assert_grep "Summary" "$TMP_ROOT/push-missing-local.out"
	assert_grep "Cannot push" "$TMP_ROOT/push-missing-local.out"
	assert_grep "missing on origin: feature/a" "$TMP_ROOT/push-missing-local.out"

	add_feature_branch "feature/b"
	git push -q origin feature/b
	"$GIT_LM" create demo feature/b --base main > "$TMP_ROOT/success-missing-remote.out" 2>&1
	assert_grep "remote:" "$TMP_ROOT/success-missing-remote.out"
	assert_grep "features: .*feature/a" "$TMP_ROOT/success-missing-remote.out"
	assert_grep "missing on origin: feature/a" "$TMP_ROOT/success-missing-remote.out"
	assert_line_order "remote:" "Warning: missing on origin: feature/a" "$TMP_ROOT/success-missing-remote.out"

	if "$GIT_LM" pull demo > "$TMP_ROOT/pull-missing-remote.out" 2>&1; then
		fail "pull with missing remote feature unexpectedly succeeded"
	fi
	assert_grep "Summary" "$TMP_ROOT/pull-missing-remote.out"
	assert_grep "Cannot pull" "$TMP_ROOT/pull-missing-remote.out"
	assert_grep "missing on origin: feature/a" "$TMP_ROOT/pull-missing-remote.out"

	"$GIT_LM" status demo > "$TMP_ROOT/status-inconsistent-missing-remote.out" 2>&1
	assert_line_order "local:" "remote:" "$TMP_ROOT/status-inconsistent-missing-remote.out"
	assert_line_order "remote:" "Warning: missing on origin: feature/a" "$TMP_ROOT/status-inconsistent-missing-remote.out"
	local purple_feature
	purple_feature=$(printf '\033\\[35mfeature/b')
	assert_grep "$purple_feature" "$TMP_ROOT/status-inconsistent-missing-remote.out"

	"$GIT_LM" list > "$TMP_ROOT/list-inconsistent-missing-remote.out" 2>&1
	assert_line_order "local:" "remote:" "$TMP_ROOT/list-inconsistent-missing-remote.out"
	assert_line_order "remote:" "Warning: missing on origin: feature/a" "$TMP_ROOT/list-inconsistent-missing-remote.out"
	assert_not_grep "light-merge/demo.*local:" "$TMP_ROOT/list-inconsistent-missing-remote.out"
	assert_grep "^      features: .*feature/b" "$TMP_ROOT/list-inconsistent-missing-remote.out"
	assert_grep "^      features: .*feature/a" "$TMP_ROOT/list-inconsistent-missing-remote.out"
	assert_grep "$purple_feature" "$TMP_ROOT/list-inconsistent-missing-remote.out"

	git checkout -q main
	git branch -D light-merge/demo >/dev/null 2>&1
	if "$GIT_LM" sync demo > "$TMP_ROOT/sync-missing-remote.out" 2>&1; then
		fail "sync with missing remote feature unexpectedly succeeded"
	fi
	assert_grep "remote-only" "$TMP_ROOT/sync-missing-remote.out"
	assert_grep "Cannot pull" "$TMP_ROOT/sync-missing-remote.out"
	assert_grep "missing on origin: feature/a" "$TMP_ROOT/sync-missing-remote.out"

	add_feature_branch "feature/c-long-name"
	git push -q origin feature/c-long-name
	add_feature_branch "feature/d-long-name"
	git push -q origin feature/d-long-name
	"$GIT_LM" create wrap feature/b feature/c-long-name feature/d-long-name --base main > "$TMP_ROOT/wrap-create.out" 2>&1
	GIT_LM_WRAP_WIDTH=60 "$GIT_LM" list > "$TMP_ROOT/wrap-narrow.out" 2>&1
	GIT_LM_WRAP_WIDTH=200 "$GIT_LM" list > "$TMP_ROOT/wrap-wide.out" 2>&1
	GIT_LM_WRAP_WIDTH=10 "$GIT_LM" list > "$TMP_ROOT/wrap-disabled.out" 2>&1
	assert_grep "^              .*feature/" "$TMP_ROOT/wrap-narrow.out"
	assert_line_count 0 "^              .*feature/" "$TMP_ROOT/wrap-wide.out"
	assert_line_count 0 "^              .*feature/" "$TMP_ROOT/wrap-disabled.out"

	printf "status tests passed.\n"
}

test_checkout() {
	printf "Running checkout tests...\n"

	local repo="$TMP_ROOT/checkout-work"
	local origin="$TMP_ROOT/checkout-origin.git"
	init_repo "$repo"
	add_origin "$origin"
	add_feature_branch "feature/a"
	git push -q origin feature/a

	"$GIT_LM" create demo feature/a --base main > "$TMP_ROOT/checkout-create.out" 2>&1
	git checkout -q main
	"$GIT_LM" checkout demo > "$TMP_ROOT/checkout-local.out" 2>&1
	assert_grep "Switching to local light-merge branch 'light-merge/demo'" "$TMP_ROOT/checkout-local.out"
	[[ "$(git branch --show-current)" == "light-merge/demo" ]] || fail "checkout did not switch to the local LM branch"

	"$GIT_LM" push demo > "$TMP_ROOT/checkout-push.out" 2>&1
	git checkout -q main
	git branch -D light-merge/demo >/dev/null
	"$GIT_LM" co demo > "$TMP_ROOT/checkout-remote.out" 2>&1
	assert_grep "Creating local tracking branch 'light-merge/demo'" "$TMP_ROOT/checkout-remote.out"
	[[ "$(git branch --show-current)" == "light-merge/demo" ]] || fail "checkout did not create and switch to the remote LM branch"
	[[ "$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')" == "origin/light-merge/demo" ]] || fail "remote LM branch is not tracked"

	"$GIT_LM" create second feature/a --base main > "$TMP_ROOT/checkout-second-create.out" 2>&1
	cat > "$TMP_ROOT/select-second" <<'EOF'
#!/usr/bin/env bash
cat >/dev/null
printf 'second\n'
EOF
	chmod +x "$TMP_ROOT/select-second"
	git checkout -q light-merge/demo
	GIT_LM_PICKER_PLUGIN="$TMP_ROOT/select-second" "$GIT_LM" co > "$TMP_ROOT/checkout-select.out" 2>&1
	[[ "$(git branch --show-current)" == "light-merge/second" ]] || fail "checkout did not offer task selection from an LM branch"

	printf "checkout tests passed.\n"
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
	assert_grep "Summary" "$TMP_ROOT/sync-local-only.out"
	assert_grep "Target: .*light-merge/demo" "$TMP_ROOT/sync-local-only.out"

	git fetch -q origin
	"$GIT_LM" sync demo > "$TMP_ROOT/sync-up-to-date.out" 2>&1
	assert_grep "already in sync" "$TMP_ROOT/sync-up-to-date.out"
	assert_grep "Summary" "$TMP_ROOT/sync-up-to-date.out"
	assert_grep "Target: .*light-merge/demo" "$TMP_ROOT/sync-up-to-date.out"

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

	assert_grep "\[ 1\] \[1\] feature/a" "$TMP_ROOT/pick-fallback.out"
	assert_grep "\[ 2\] \[ \] feature/b" "$TMP_ROOT/pick-fallback.out"
	assert_grep "feature/b \[local only\]" "$TMP_ROOT/pick-fallback.out"
	assert_grep "Local-only branches are shown for visibility but cannot be selected" "$TMP_ROOT/pick-fallback.out"
	assert_grep "Enter keeps the numbered order" "$TMP_ROOT/pick-fallback.out"
	assert_grep "Selected features: feature/a" "$TMP_ROOT/pick-fallback.out"
	assert_grep "Success" "$TMP_ROOT/pick-fallback.out"

	add_feature_branch "feature/c"
	git checkout -q feature/c
	GIT_AUTHOR_DATE="2030-01-01T00:00:00Z" GIT_COMMITTER_DATE="2030-01-01T00:00:00Z" git commit -q --amend --no-edit
	git checkout -q main
	git push -q origin feature/c
	printf '2 1\n' | GIT_LM_PICKER_PLUGIN="$TMP_ROOT/missing-picker" "$GIT_LM" pick demo --base main > "$TMP_ROOT/pick-reorder.out" 2>&1
	assert_grep "\[ 1\] \[1\] feature/a" "$TMP_ROOT/pick-reorder.out"
	assert_grep "\[ 2\] \[ \] feature/c" "$TMP_ROOT/pick-reorder.out"
	assert_grep "Selected features: feature/c feature/a" "$TMP_ROOT/pick-reorder.out"
	assert_grep "Success" "$TMP_ROOT/pick-reorder.out"

	printf "pick tests passed.\n"
}

test_prune() {
	printf "Running prune tests...\n"

	local repo="$TMP_ROOT/prune-work"
	init_repo "$repo"
	git branch light-merge/active

	local pending_root
	pending_root="$(git rev-parse --git-dir)/light-merge-pending"
	mkdir -p "$pending_root/light-merge__active" "$pending_root/light-merge__orphan"
	touch "$pending_root/light-merge__active/pending" "$pending_root/light-merge__orphan/pending"

	"$GIT_LM" prune > "$TMP_ROOT/prune.out" 2>&1
	[[ -d "$pending_root/light-merge__active" ]] || fail "active pending state was removed"
	[[ ! -e "$pending_root/light-merge__orphan" ]] || fail "orphan pending state was not removed"
	assert_grep "Cleaned up 1 orphaned conflict state" "$TMP_ROOT/prune.out"

	printf "prune tests passed.\n"
}

usage() {
	cat <<EOF
Usage: scripts/smoke-test.sh [all|syntax|create|status|checkout|sync|refresh|pick|prune]...

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
			test_checkout
			test_sync
			test_refresh
			test_pick
			test_prune
			;;
		syntax) test_syntax ;;
		create) test_create ;;
		status) test_status ;;
		checkout) test_checkout ;;
		sync) test_sync ;;
		refresh) test_refresh ;;
		pick) test_pick ;;
		prune) test_prune ;;
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