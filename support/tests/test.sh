#!/bin/bash

cd `dirname $0`
CWD="`pwd`"

box $CWD/runtests.cfm

exitcode=$(<.exitcode)
rm -f .exitcode

exit $exitcode