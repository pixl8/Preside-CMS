#!/bin/bash

cd `dirname $0`
CWD="`pwd`"
PACKAGE_DIR="${CWD}/package"

if [[ $TRAVIS_JDK_VERSION == 'openjdk7' ]] ; then
	echo "Finished (only run tests on JDK 7, builds performed in the JDK8 environment)."
	exit 0;
fi

if  [[ $TRAVIS_PULL_REQUEST == 'true' ]] ; then
	echo "Finished (not publishing due to running in a pull request)."
	exit 0;
fi

if [[ $TRAVIS_TAG == v* ]] || [[ $TRAVIS_BRANCH == release* ]] ; then
	cd $PACKAGE_DIR
	if [[ $TRAVIS_BRANCH == release* ]] ; then
		sed -i 's/"slug":"presidecms"/"slug":"preside-be"/' box.json
		sed -i 's/"name":"Preside"/"name":"Preside Bleeding Edge Build"/' box.json
	fi
	box forgebox login username="$FORGEBOXUSER" password="$FORGEBOXPASS" || exit 1;
	box publish || exit 1
else
	echo "Skipping publishing, not on stable or release branch in a travis build."
fi
