#!/bin/sh

test_description='push.allowForcePush configuration blocks force pushing'

GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=main
export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME

. ./test-lib.sh

mk_repo_pair () {
	rm -rf workbench upstream &&
	test_create_repo upstream &&
	test_create_repo workbench &&
	(
		cd upstream &&
		git config receive.denyCurrentBranch warn
	) &&
	(
		cd workbench &&
		git remote add up ../upstream
	)
}

setup_commits () {
	(
		cd workbench &&
		test_commit initial &&
		git push up main
	)
}

test_expect_success 'push.allowForcePush=false blocks --force' '
	mk_repo_pair &&
	setup_commits &&
	(
		cd workbench &&
		git config push.allowForcePush false &&
		test_must_fail git push --force up main 2>err &&
		test_grep "configured this git client to prevent rewriting history" err
	)
'

test_expect_success 'push.allowForcePush=false blocks --force-with-lease' '
	mk_repo_pair &&
	setup_commits &&
	(
		cd workbench &&
		git config push.allowForcePush false &&
		test_must_fail git push --force-with-lease up main 2>err &&
		test_grep "configured this git client to prevent rewriting history" err
	)
'

test_expect_success 'push.allowForcePush=false blocks --mirror' '
	mk_repo_pair &&
	setup_commits &&
	(
		cd workbench &&
		git config push.allowForcePush false &&
		test_must_fail git push --mirror up 2>err &&
		test_grep "configured this git client to prevent rewriting history" err
	)
'

test_expect_success 'push.allowForcePush=false allows normal push' '
	mk_repo_pair &&
	setup_commits &&
	(
		cd workbench &&
		git config push.allowForcePush false &&
		test_commit second &&
		git push up main
	)
'

test_expect_success 'push.allowForcePush=true allows --force' '
	mk_repo_pair &&
	setup_commits &&
	(
		cd workbench &&
		git config push.allowForcePush true &&
		git push --force up main
	)
'

test_expect_success 'unset push.allowForcePush allows --force (default)' '
	mk_repo_pair &&
	setup_commits &&
	(
		cd workbench &&
		test_unconfig push.allowForcePush &&
		git push --force up main
	)
'

test_done
