#!/usr/bin/env bats

setup() {
	TEST_ROOT="$BATS_TEST_TMPDIR/projects"
	PROJECTS_DIR="$TEST_ROOT"
	FAKE_BIN="$BATS_TEST_TMPDIR/bin"
	SCRIPT="$BATS_TEST_DIRNAME/../archive/general/prjsync"
	GIT_LOG="$BATS_TEST_TMPDIR/git.log"

	mkdir -p "$FAKE_BIN" \
		"$PROJECTS_DIR/.personal/repo-hidden/.git" \
		"$PROJECTS_DIR/repo-top/.git" \
		"$PROJECTS_DIR/no-remote/.git" \
		"$PROJECTS_DIR/team/repo-nested" \
		"$PROJECTS_DIR/.worktrees/worktree-repo/.git"
	printf 'gitdir: /tmp/fake\n' > "$PROJECTS_DIR/team/repo-nested/.git"

	cat > "$FAKE_BIN/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

repo_path=''
git_args=$*
if [[ "${1:-}" == '-C' ]]; then
	repo_path=$2
	shift 2
fi

printf '%s %s\n' "$repo_path" "$git_args" >> "$GIT_LOG"

case "$1" in
	remote)
		case "$repo_path" in
			"$PROJECTS_DIR/no-remote")
				;;
			"$PROJECTS_DIR"/*)
				printf 'origin\n'
				;;
			*)
				printf 'unexpected remote lookup for %s\n' "$repo_path" >&2
				exit 1
				;;
		esac
		;;
	pull)
		case "$repo_path" in
			"$PROJECTS_DIR/failing-repo")
				printf 'fatal: simulated failure\n' >&2
				exit 1
				;;
			"$PROJECTS_DIR/team/repo-nested")
				printf 'Updating 123..456\nFast-forward\n'
				;;
			"$PROJECTS_DIR"/*)
				printf 'Already up to date.\n'
				;;
			*)
				printf 'unexpected pull for %s\n' "$repo_path" >&2
				exit 1
				;;
		esac
		;;
	*)
		printf 'unexpected git invocation: %s\n' "$*" >&2
		exit 1
		;;
esac
EOF
	chmod +x "$FAKE_BIN/git"
}

@test 'updates nested repositories, includes .personal, and prints a summary' {
	run env \
		PATH="$FAKE_BIN:$PATH" \
		PROJECTS_DIR="$PROJECTS_DIR" \
		GIT_LOG="$GIT_LOG" \
		"$SCRIPT"

	[[ "$status" -eq 0 ]]
	[[ "$output" == *'[1/4] .personal/repo-hidden'* ]]
	[[ "$output" == *'[2/4] no-remote'* ]]
	[[ "$output" == *'[3/4] repo-top'* ]]
	[[ "$output" == *'[4/4] team/repo-nested'* ]]
	[[ "$output" == *'No remotes configured.'* ]]
	[[ "$output" == *'Already up to date.'* ]]
	[[ "$output" == *'Updating 123..456'* ]]
	[[ "$output" == *'Result: [UPDATED]'* ]]
	[[ "$output" == *'Result: [SKIPPED]'* ]]
	[[ "$output" == *'Summary: 3 updated, 1 skipped, 0 failed.'* ]]
	[[ "$output" == *$'Updated:\n  - .personal/repo-hidden\n  - repo-top\n  - team/repo-nested'* ]]
	[[ "$output" == *$'Skipped:\n  - no-remote'* ]]
	[[ "$output" != *'worktree-repo'* ]]

	run grep -F "$PROJECTS_DIR/.personal/repo-hidden -C $PROJECTS_DIR/.personal/repo-hidden pull" "$GIT_LOG"
	[[ "$status" -eq 0 ]]
	run grep -F "$PROJECTS_DIR/team/repo-nested -C $PROJECTS_DIR/team/repo-nested pull" "$GIT_LOG"
	[[ "$status" -eq 0 ]]
}

@test 'returns a failing status after processing every repository' {
	mkdir -p "$PROJECTS_DIR/failing-repo/.git"

	run env \
		PATH="$FAKE_BIN:$PATH" \
		PROJECTS_DIR="$PROJECTS_DIR" \
		GIT_LOG="$GIT_LOG" \
		"$SCRIPT"

	[[ "$status" -eq 1 ]]
	[[ "$output" == *'[2/5] failing-repo'* ]]
	[[ "$output" == *'fatal: simulated failure'* ]]
	[[ "$output" == *'Result: [FAILED]'* ]]
	[[ "$output" == *'Summary: 3 updated, 1 skipped, 1 failed.'* ]]
	[[ "$output" == *$'Failed:\n  - failing-repo'* ]]
}
