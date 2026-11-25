#!/usr/bin/env bats

setup() {
	TEST_ROOT="$BATS_TEST_TMPDIR/projects"
	PROJECTS_DIR="$TEST_ROOT"
	WORKTREES_DIR="$PROJECTS_DIR/.worktrees"
	REPO_DIR="$PROJECTS_DIR/sample-repo"
	SCRIPT="$BATS_TEST_DIRNAME/../git/cleanup-worktrees"

	mkdir -p "$PROJECTS_DIR"
	git init "$REPO_DIR" >/dev/null
	git -C "$REPO_DIR" config user.name test
	git -C "$REPO_DIR" config user.email test@example.com
	printf 'base\n' > "$REPO_DIR/file.txt"
	git -C "$REPO_DIR" add file.txt
	git -C "$REPO_DIR" commit -m 'init' >/dev/null
	git -C "$REPO_DIR" branch feature-a
	git -C "$REPO_DIR" branch feature-b
	mkdir -p "$WORKTREES_DIR"
	git -C "$REPO_DIR" worktree add "$WORKTREES_DIR/feature-a" feature-a >/dev/null
	git -C "$REPO_DIR" worktree add "$WORKTREES_DIR/feature-b" feature-b >/dev/null
}

@test 'removes a single selected worktree' {
	printf 'dirty\n' >> "$WORKTREES_DIR/feature-a/file.txt"

	run bash -c "printf 'j \n' | PROJECTS_DIR='$PROJECTS_DIR' WORKTREES_DIR='$WORKTREES_DIR' '$SCRIPT'"

	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Removed feature-a.'* ]]
	[[ ! -d "$WORKTREES_DIR/feature-a" ]]
	[[ -d "$WORKTREES_DIR/feature-b" ]]
}

@test 'removes all worktrees' {
	printf 'dirty-a\n' >> "$WORKTREES_DIR/feature-a/file.txt"
	printf 'dirty-b\n' >> "$WORKTREES_DIR/feature-b/file.txt"

	run bash -c "printf '\n' | PROJECTS_DIR='$PROJECTS_DIR' WORKTREES_DIR='$WORKTREES_DIR' '$SCRIPT'"

	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Removed feature-a.'* ]]
	[[ ! -d "$WORKTREES_DIR/feature-a" ]]
	[[ ! -d "$WORKTREES_DIR/feature-b" ]]
}

@test 'aborts on q without removing' {
	run bash -c "printf 'q' | PROJECTS_DIR='$PROJECTS_DIR' WORKTREES_DIR='$WORKTREES_DIR' '$SCRIPT'"

	[[ "$status" -eq 0 ]]
	[[ "$output" == *'Aborted.'* ]]
	[[ -d "$WORKTREES_DIR/feature-a" ]]
}
