#!/bin/bash

cd `dirname $0`
CWD="`pwd`"
PACKAGE_DIR="${CWD}/package"

if [[ $TRAVIS_JDK_VERSION == 'openjdk7' ]] ; then
	echo "Finished (only run tests on JDK 7, builds performed in the JDK8 environment)."
	exit 0;
fi

if  [[ $TRAVIS_PULL_REQUEST != 'false' ]] ; then
	echo "Finished (not publishing due to running in a pull request)."
	exit 0;
fi

if [[ $TRAVIS_TAG == v* ]] || [[ $TRAVIS_BRANCH == release* ]] ; then
	cd $PACKAGE_DIR
	box forgebox login username="$FORGEBOXUSER" password="$FORGEBOXPASS" || exit 1;
	box publish || exit 1
else
	echo "Skipping publishing, not on stable or release branch in a travis build."
fi
