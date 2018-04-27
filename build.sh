#!/bin/bash

cd `dirname $0`
CWD="`pwd`"

echo "";
echo "-----------------------------------------------------";
echo "Welcome to the Preside Test runner and build suite :)";
echo "-----------------------------------------------------";
echo "";
echo "This script will install dependencies, run tests, and conditionally package preside into a ZIP file.";
echo "Each of these operations can be run independently with the following commands:";
echo "";
echo "box install                                   - installs dependencies";
echo "cd system/assets/ && npm install && grunt all - builds static assets";
echo "./test.sh                                     - runs tests";
echo "ant -f ./support/build/build.xml              - packages Preside into a zip file";
echo "";
echo "The script has dependencies on CommandBox, ant + an accessible database for running the test suite.";
echo "";
echo "-------------------------------------------------------";

echo "";
echo "Installing dependencies via box.json...";
echo "";
box install --force save=false || exit 1;
rm -rf ./system/externals/lucee-spreadsheet/javaLoader;
rm -rf ./system/externals/lucee-spreadsheet/test;


echo "";
echo "Building static assets with grunt";
echo "";

cd system/assets;
npm install || exit 1;
grunt all || exit 1;
cd ../../;

echo "";
echo "Running tests (please be patient, expect this to take several minutes)...";
echo "";


./test.sh || exit 1;

if [[ $TRAVIS_JDK_VERSION == 'openjdk7' ]] ; then
	echo "Finished (only run tests on JDK 7, builds performed in the JDK8 environment)."
	exit 0;
fi

if  [[ $TRAVIS_PULL_REQUEST == 'true' ]] ; then
	echo "Finished (not packaging up source due to running in a pull request)."
	exit 0;
fi

if [[ $TRAVIS_TAG == v* ]] || [[ $TRAVIS_BRANCH == release* ]] ; then
	if [[ $TRAVIS_TAG == v* ]] ; then
		VERSION_NUMBER="${TRAVIS_TAG//v}"
	elif [[ $TRAVIS_BRANCH == release* ]] ; then
		VERSION_NUMBER="${TRAVIS_BRANCH//release-}"
	else
		VERSION_NUMBER="unknown"
	fi

	echo "Packaging application ${VERSION_NUMBER}...";
	echo "";
	echo "";

	ant -f support/build/build.xml -Dbranch=$TRAVIS_BRANCH -Dtag=$TRAVIS_TAG -Dversionnumber=$VERSION_NUMBER
else
	echo "Skipping packaging, not on stable or release branch in a travis build. To package preside yourself, run ant -f ./support/build/build.xml"
fi

echo "";
echo "All done :)";
echo "";

exit 0;
