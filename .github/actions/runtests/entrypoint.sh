#!/bin/bash
TEST_DIR=$GITHUB_WORKSPACE/tests

cd $TEST_DIR
./test.sh || exit 1