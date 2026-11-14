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

@test 'pre-selects squash-merged branch and deletes on Enter' {
	git switch --quiet -c feature
	echo a > a && git add a && git commit --quiet -m a
	git switch --quiet main
	git merge --quiet --squash feature && git commit --quiet -m squash && git push --quiet

	run git-branch-cleanup <<<""
	[[ $status -eq 0 ]]
	[[ $output == *"Deleted 'feature'."* ]]
	! git show-ref --quiet --verify refs/heads/feature
}

@test 'leaves unmerged branch unselected by default and toggles with Space' {
	git switch --quiet -c unmerged
	echo b > b && git add b && git commit --quiet -m b
	git switch --quiet main

	run git-branch-cleanup <<<""
	[[ $status -eq 0 ]]
	[[ $output == *'No branches deleted.'* ]]
	git show-ref --quiet --verify refs/heads/unmerged

	run git-branch-cleanup <<<' '
	[[ $status -eq 0 ]]
	[[ $output == *"Deleted 'unmerged'."* ]]
	! git show-ref --quiet --verify refs/heads/unmerged
}

@test 'navigates list and toggles selection before Enter' {
	git switch --quiet -c a-merged
	echo a > a && git add a && git commit --quiet -m a
	git switch --quiet main
	git merge --quiet --squash a-merged && git commit --quiet -m squash && git push --quiet

	git switch --quiet -c b-unmerged
	echo b > b && git add b && git commit --quiet -m b
	git switch --quiet main

	# Space deselects a-merged, j moves to b-unmerged, Space selects b-unmerged, Enter runs.
	run git-branch-cleanup <<<' j '
	[[ $status -eq 0 ]]
	git show-ref --quiet --verify refs/heads/a-merged
	! git show-ref --quiet --verify refs/heads/b-unmerged
}

@test 'aborts on q without deleting pre-selected branches' {
	git switch --quiet -c feature
	git push --quiet origin feature:main
	git switch --quiet main

	run git-branch-cleanup <<<q
	[[ $status -eq 0 ]]
	[[ $output == *'Aborted.'* ]]
	git show-ref --quiet --verify refs/heads/feature
}

@test 'skips current and default branches' {
	git switch --quiet -c current-branch
	echo c > c && git add c && git commit --quiet -m c

	run git-branch-cleanup <<<""
	[[ $status -eq 0 ]]
	[[ $output == *'No branches to clean up.'* ]]
	git show-ref --quiet --verify refs/heads/main
	git show-ref --quiet --verify refs/heads/current-branch
}
