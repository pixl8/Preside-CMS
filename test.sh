#!/bin/bash

exitcode=0

box stop name="presidetests"
box start directory="./support/tests"
box testbox run verbose=false || exitcode=1
box stop name="presidetests"

exit $exitcode
