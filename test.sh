#!/bin/bash

exitcode=0

box stop name="presidetests"
box start directory="./support/tests" serverConfigFile="./support/tests/server-presidetests.json"
box testbox run verbose=false || exitcode=1
box stop name="presidetests"

exit $exitcode
