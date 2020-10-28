#!/bin/bash
TEST_DIR=$GITHUB_WORKSPACE/support/tests

cd $GITHUB_WORKSPACE
./support/build/install.sh

cd $TEST_DIR
./test.sh || exit 1