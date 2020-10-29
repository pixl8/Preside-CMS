#!/bin/bash

cd `dirname $0`

exitcode=0

box stop name="presidetests"
box start directory="./" serverConfigFile="./server-presidetests.json"
box testbox run verbose=false || exitcode=1
box stop name="presidetests"

exit $exitcode
