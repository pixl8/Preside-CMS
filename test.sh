#!/bin/bash

cd `dirname $0`/support/tests
CWD="`pwd`"

box $CWD/runtests.cfm

exitcode=$(<.exitcode)
rm -f .exitcode

exit $exitcode