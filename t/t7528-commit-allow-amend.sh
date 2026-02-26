#!/bin/sh

test_description='commit.allowAmend configuration blocks amending commits'

GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=main
export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME

. ./test-lib.sh

test_expect_success 'setup: create initial commit' '
	echo "initial content" >file.txt &&
	git add file.txt &&
	git commit -m "initial commit"
'

test_expect_success 'commit.allowAmend=false blocks --amend' '
	git config commit.allowAmend false &&
	test_must_fail git commit --amend -m "amended" 2>err &&
	test_grep "configured this git client to prevent amending commits" err
'

test_expect_success 'commit.allowAmend=false allows --amend with --no-verify' '
	git config commit.allowAmend false &&
	git commit --amend --no-verify -m "amended with bypass"
'

test_expect_success 'commit.allowAmend=false allows normal commit' '
	git config commit.allowAmend false &&
	echo "new content" >file2.txt &&
	git add file2.txt &&
	git commit -m "normal commit"
'

test_expect_success 'commit.allowAmend=true allows --amend' '
	git config commit.allowAmend true &&
	git commit --amend -m "amended when allowed"
'

test_expect_success 'unset commit.allowAmend allows --amend (default)' '
	test_unconfig commit.allowAmend &&
	git commit --amend -m "amended when unset"
'

test_done
