#!/usr/bin/env bats

setup() {
	TEST_ROOT="$BATS_TEST_TMPDIR/projects"
	REPO_DIR="$TEST_ROOT/sample-repo"
	SCRIPT="$BATS_TEST_DIRNAME/../git/git-origin-http-to-ssh"

	mkdir -p "$TEST_ROOT"
	git init "$REPO_DIR" >/dev/null
	git -C "$REPO_DIR" config user.name test
	git -C "$REPO_DIR" config user.email test@example.com
	printf 'base\n' > "$REPO_DIR/file.txt"
	git -C "$REPO_DIR" add file.txt
	git -C "$REPO_DIR" commit -m 'init' >/dev/null
	# Create a dummy remote that looks like HTTPS (with username)
	git -C "$REPO_DIR" remote add origin "https://matwoess@github.com/matwoess/scriptmonkey.git"
}

@test 'converts http origin with username to ssh' {
	# We mock git fetch since we do not want to hit the network
	# But wait, git-origin-http-to-ssh runs:
	#   git remote remove origin
	#   git remote add origin "$ssh_url"
	#   git fetch origin
	#   upstream_ref="$(detect_upstream_ref)"
	# Since it runs "git fetch origin" and "detect_upstream_ref" which reads origin/main or origin/master,
	# git fetch will fail without internet or a real remote.
	# We can mock/override the git command, or we can just unit-test the functions by sourcing the script!
	# Since the script starts with set -euo pipefail and runs main, we can source it if we run it in a way
	# that doesn't run main (e.g. if we check a variable, or if we just test to_ssh_url specifically).
	# Wait, does the script call main immediately? Yes: `main "$@"` at the end.
	# If we source it, main runs.
	# But we can test the whole script by mocking git fetch!
	# We can create a fake git binary or alias, or we can mock it by setting up a local git repository as remote.
	# Yes! A local git repository as a remote is extremely easy:
	# We can set the URL to a local repo URL: "https://matwoess@github.com/..."
	# But git remote set-url/add origin allows any URL. Fetching from it will fail.
	# If we mock `git` by putting a mock git in the PATH, we can control its output!
	# Or, since git-origin-http-to-ssh calls `git fetch origin`, we can create a dummy bash function for `git` or write a wrapper script.
	# Let's write a simple bats test that defines a mock git.

	# Let's create a mock git script in the PATH:
	MOCK_BIN_DIR="$BATS_TEST_TMPDIR/bin"
	mkdir -p "$MOCK_BIN_DIR"
	cat <<'EOF' > "$MOCK_BIN_DIR/git"
#!/usr/bin/env bash
if [[ "$*" == "fetch origin" ]]; then
	# Create the remote refs manually to mock a successful fetch
	mkdir -p .git/refs/remotes/origin
	echo "refs/heads/main" > .git/refs/remotes/origin/main
	exit 0
fi
exec /usr/bin/git "$@"
EOF
	chmod +x "$MOCK_BIN_DIR/git"

	export PATH="$MOCK_BIN_DIR:$PATH"
	cd "$REPO_DIR"

	run "$SCRIPT"

	[[ "$status" -eq 0 ]]
	# Verify remote URL is updated to the expected SSH URL
	local updated_url
	updated_url=$(/usr/bin/git remote get-url origin)
	[[ "$updated_url" == "git@github.com:matwoess/scriptmonkey.git" ]]
}
