#!/bin/bash
TEST_DIR=$GITHUB_WORKSPACE/support/tests

cd $TEST_DIR
box install || exit 1
./test.sh || exit 1