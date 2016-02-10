#!/bin/bash

cd `dirname $0`
CWD="`pwd`"

echo "";
echo "--------------------------------------------------------";
echo "Welcome to the PresideCMS Test runner and build suite :)";
echo "--------------------------------------------------------";
echo "";
echo "This script will install dependencies, run tests, and conditionally build docs and package preside into a ZIP file.";
echo "Each of these operations can be run independantly with the following commands:";
echo "";
echo "box install                      - installs dependencies";
echo "./test.sh                        - runs tests";
echo "./support/docs/build.sh          - builds documentation";
echo "ant -f ./support/build/build.xml - packages PresideCMS into a zip file";
echo "";
echo "The script has dependencies on CommandBox, ant + an accessible database for running the test suite.";
echo "";
echo "-------------------------------------------------------";
echo "";
echo "Installing dependencies via box.json...";
echo "";

box install --force
rm -rf ./system/externals/lucee-spreadsheet/javaLoader
rm -rf ./system/externals/lucee-spreadsheet/test

echo "";
echo "Running tests (please be patient, expect this to take several minutes)...";
echo "";


./test.sh || exit 1;

if  [[ $TRAVIS_PULL_REQUEST == 'true' ]] ; then
	echo "Finished. (not packaging up docs or source due to running in a pull request)."
	exit 0;
fi

if [[ $TRAVIS_TAG == v* ]] ; then
	./support/docs/build.sh

	echo "";
	echo "";
else
	echo "Skipping docs build, not on a release tag in a travis build. To build the docs yourself, run ./support/docs/build.sh"
fi
if [[ $TRAVIS_TAG == v* ]] || [[ $TRAVIS_BRANCH == release* ]] ; then
	echo "Packaging up as zip file...";
	echo "";
	echo "";

	ant -f support/build/build.xml -Dbranch=$TRAVIS_BRANCH -Dtag=$TRAVIS_TAG
else
	echo "Skipping packaging, not on stable or release branch in a travis build. To package preside yourself, run ant -f ./support/build/build.xml"
fi

echo "";
echo "All done :)";
echo "";

exit 0;