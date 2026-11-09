#!/usr/bin/env bats

setup() {
	PATH="$BATS_TEST_DIRNAME/../git:$PATH"
	export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
	git init --quiet --bare -b main "$BATS_TEST_TMPDIR/remote.git"
	git clone --quiet "$BATS_TEST_TMPDIR/remote.git" "$BATS_TEST_TMPDIR/repo" 2>/dev/null
	cd "$BATS_TEST_TMPDIR/repo"
	git commit --quiet --allow-empty -m init
	git push --quiet -u origin main
	git remote set-head origin main
	git switch --quiet -c feature
	echo a > a && git add a && git commit --quiet -m a
}

@test 'default branch from origin/HEAD, falls back to master' {
	run git-default-branch
	[[ $status -eq 0 && $output == main ]]
	git remote set-head origin -d
	git branch --quiet -m main master
	git update-ref -d refs/remotes/origin/main
	run git-default-branch
	[[ $output == master ]]
}

@test 'deletes squash-merged current branch without prompt and switches to main' {
	git switch --quiet main
	git merge --quiet --squash feature && git commit --quiet -m squash && git push --quiet
	git reset --quiet --hard HEAD~1 && git switch --quiet feature
	run grmbranch </dev/null
	[[ $status -eq 0 ]]
	[[ $(git branch --show-current) == main && -f a ]]
	! git show-ref --quiet --verify refs/heads/feature
}

@test 'deletes fast-forward-merged branch by name' {
	git push --quiet origin feature:main
	git switch --quiet main
	run grmbranch feature
	[[ $status -eq 0 ]]
	! git show-ref --quiet --verify refs/heads/feature
}

@test 'unmerged branch is kept unless confirmed' {
	run grmbranch <<<n
	[[ $status -eq 1 ]]
	git show-ref --quiet --verify refs/heads/feature
}

@test 'refuses to delete default branch' {
	git switch --quiet main
	run grmbranch
	[[ $status -eq 1 && $output == *'refusing'* ]]
}
