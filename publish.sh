#!/bin/bash

if [[ $TRAVIS_TAG == v* ]] || [[ $TRAVIS_BRANCH == release* ]] ; then
	mv box.json box.json.orig
	mv box.json.no.deps box.json
	if [[ $TRAVIS_BRANCH == release* ]] ; then
		sed -i 's/"name":"PresideCMS"/"name":"preside-be"/' box.json
	fi
	box forgebox login username="$FORGEBOXUSER" password="$FORGEBOXPASS";
	box publish
	mv box.json box.json.no.deps
	mv box.json.orig box.json
else
	echo "Skipping publishing, not on stable or release branch in a travis build."
fi
