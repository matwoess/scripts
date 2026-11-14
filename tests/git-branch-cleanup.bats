#!/usr/bin/env bats

setup() {
	PATH="$BATS_TEST_DIRNAME/../git:$PATH"
	export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
	git init --quiet --bare -b main "$BATS_TEST_TMPDIR/remote.git"
	git clone --quiet "$BATS_TEST_TMPDIR/remote.git" "$BATS_TEST_TMPDIR/repo" 2>/dev/null
	cd "$BATS_TEST_TMPDIR/repo" || return
	git commit --quiet --allow-empty -m init
	git push --quiet -u origin main
	git remote set-head origin main
}

@test 'deletes squash-merged branch with single confirmation' {
	git switch --quiet -c feature
	echo a > a && git add a && git commit --quiet -m a
	git switch --quiet main
	git merge --quiet --squash feature && git commit --quiet -m squash && git push --quiet

	run git-branch-cleanup <<<y
	[[ $status -eq 0 ]]
	[[ $output == *"Deleted 'feature'."* ]]
	! git show-ref --quiet --verify refs/heads/feature
}

@test 'keeps unmerged branch when declined and deletes when confirmed' {
	git switch --quiet -c unmerged
	echo b > b && git add b && git commit --quiet -m b
	git switch --quiet main

	run git-branch-cleanup <<<n
	[[ $status -eq 0 ]]
	git show-ref --quiet --verify refs/heads/unmerged

	run git-branch-cleanup <<<y
	[[ $status -eq 0 ]]
	[[ $output == *"Deleted 'unmerged'."* ]]
	! git show-ref --quiet --verify refs/heads/unmerged
}

@test 'skips current and default branches' {
	git switch --quiet -c current-branch
	echo c > c && git add c && git commit --quiet -m c

	run git-branch-cleanup <<<y
	[[ $status -eq 0 ]]
	git show-ref --quiet --verify refs/heads/main
	git show-ref --quiet --verify refs/heads/current-branch
}
