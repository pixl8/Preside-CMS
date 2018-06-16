#!/bin/bash

if [[ $TRAVIS_TAG == v* ]] || [[ $TRAVIS_BRANCH == release* ]] ; then
	mv box.json box.json.orig
	mv box.json.no.deps box.json
	if [[ $TRAVIS_BRANCH == release* ]] ; then
		sed -i 's/"slug":"presidecms"/"slug":"preside-be"/' box.json
	fi
	box forgebox login username="$FORGEBOXUSER" password="$FORGEBOXPASS" || exit 1;
	box publish || exit 1
	mv box.json box.json.no.deps
	mv box.json.orig box.json
else
	echo "Skipping publishing, not on stable or release branch in a travis build."
fi
