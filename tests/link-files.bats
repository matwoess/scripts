#!/usr/bin/env bats

setup() {
	# Create a temporary directory for our fake environment
	test_dir=$(mktemp -d)
	export HOME="$test_dir/home"
	mkdir -p "$HOME"

	# Set up a fake repository structure inside test_dir
	repo_dir="$test_dir/repo"
	mkdir -p "$repo_dir/bin" "$repo_dir/run" "$repo_dir/scripts"

	# Create some dummy files in the repo
	touch "$repo_dir/bin/dummy1" "$repo_dir/bin/dummy2"
	touch "$repo_dir/run/game1"
	touch "$repo_dir/scripts/script1"

	# Copy the link-files.sh to the fake repo directory to run it from there
	cp "$BATS_TEST_DIRNAME/../link-files.sh" "$repo_dir/"
	chmod +x "$repo_dir/link-files.sh"
}

teardown() {
	rm -rf "$test_dir"
}

@test "creates target bin directory and links files" {
	run "$repo_dir/link-files.sh"
	[[ $status -eq 0 ]]

	# Check that symlinks were created
	[[ -L "$HOME/bin/run" ]]
	[[ $(readlink "$HOME/bin/run") == "$repo_dir/run" ]]

	[[ -L "$HOME/bin/scripts" ]]
	[[ $(readlink "$HOME/bin/scripts") == "$repo_dir/scripts" ]]

	[[ -L "$HOME/bin/dummy1" ]]
	[[ $(readlink "$HOME/bin/dummy1") == "$repo_dir/bin/dummy1" ]]

	[[ -L "$HOME/bin/dummy2" ]]
	[[ $(readlink "$HOME/bin/dummy2") == "$repo_dir/bin/dummy2" ]]
}

@test "cleans up stale symlinks" {
	# Create target bin and a stale symlink pointing to repo
	mkdir -p "$HOME/bin"
	ln -s "$repo_dir/bin/stale" "$HOME/bin/stale"
	# And a symlink pointing elsewhere (should NOT be removed)
	ln -s "/usr/bin/external" "$HOME/bin/external"

	run "$repo_dir/link-files.sh"
	[[ $status -eq 0 ]]

	# Stale should be removed
	[[ ! -e "$HOME/bin/stale" ]]
	[[ ! -L "$HOME/bin/stale" ]]

	# External should remain
	[[ -L "$HOME/bin/external" ]]
	[[ $(readlink "$HOME/bin/external") == "/usr/bin/external" ]]
}

@test "updates incorrect symlinks" {
	mkdir -p "$HOME/bin"
	# Create incorrect symlink for dummy1 pointing to a different path in repo
	ln -s "$repo_dir/bin/wrong" "$HOME/bin/dummy1"

	run "$repo_dir/link-files.sh"
	[[ $status -eq 0 ]]

	# dummy1 should now point to correct path
	[[ $(readlink "$HOME/bin/dummy1") == "$repo_dir/bin/dummy1" ]]
}

@test "handles non-symlink target collisions gracefully" {
	mkdir -p "$HOME/bin"
	# Create a regular file where dummy1 link should be
	touch "$HOME/bin/dummy1"

	# Run script and verify it fails or logs error (currently exit 1 due to set -e)
	run "$repo_dir/link-files.sh"
	[[ $status -ne 0 ]]
}
