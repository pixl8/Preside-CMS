#!/bin/bash

cd `dirname $0`
CWD="`pwd`"
NOW="`date`"

echo "TRAVIS_PULL_REQUEST: $TRAVIS_PULL_REQUEST"
if [[ $TRAVIS_JDK_VERSION == 'openjdk7' ]] ; then
	echo "Finished (only run tests on JDK 7, builds performed in the JDK8 environment)."
	exit 0;
fi

if  [[ $TRAVIS_PULL_REQUEST != 'false' ]] ; then
	echo "Finished (not packaging up source due to running in a pull request)."
	exit 0;
fi

if [[ $TRAVIS_TAG == v* ]] || [[ $TRAVIS_BRANCH == release* ]] ; then
	if [[ $TRAVIS_TAG == v* ]] ; then
		VERSION_NUMBER="${TRAVIS_TAG//v}"
		RELEASE_NAME="stable"
	elif [[ $TRAVIS_BRANCH == release* ]] ; then
		VERSION_NUMBER="${TRAVIS_BRANCH//release-}"
		RELEASE_NAME="bleeding-edge"
	else
		VERSION_NUMBER="unknown"
	fi
	BUILD_NUMBER=`printf %07d $TRAVIS_BUILD_NUMBER`
	VERSION_NUMBER="${VERSION_NUMBER}.${BUILD_NUMBER}"

	echo "Packaging application ${VERSION_NUMBER}...";
	echo "";
	echo "";

	PACKAGE_DIR="${CWD}/package"
	ARTIFACTS_DIR="${CWD}/artifacts/${RELEASE_NAME}"
	ZIP_FILE="${ARTIFACTS_DIR}/Preside-${VERSION_NUMBER}.zip"

	rm -rf $PACKAGE_DIR && mkdir -p $PACKAGE_DIR
	mkdir -p $ARTIFACTS_DIR
	rsync -a ../../ --exclude=".*" --exclude="$PACKAGE_DIR" --exclude="*.sh" --exclude="/support" --exclude="zanata.xml" "$PACKAGE_DIR" || exit 1

	cd $PACKAGE_DIR

	echo "";
	echo "Building static assets with grunt...";
	echo "";

	cd system/assets;
	npm install || exit 1;
	grunt all || exit 1;
	rm -rf ./node_modules
	cd ../../;

	echo "";
	echo "Setting up version files, etc..."
	echo "";

	echo '{ "version":"VERSION_NUMBER" }' > version.json
	echo Built on: $NOW > "Preside-$VERSION_NUMBER-$RELEASE_NAME.txt"

	rm box.json
	cp ../box.json box.json

	if [[ $TRAVIS_BRANCH == release* ]] ; then
		sed -i 's/"slug":"presidecms"/"slug":"preside-be"/' box.json
		sed -i 's/"name":"Preside"/"name":"Preside Bleeding Edge Build"/' box.json
	fi

	sed -i "s,VERSION_NUMBER,$VERSION_NUMBER," box.json
	sed -i "s,VERSION_NUMBER,$VERSION_NUMBER," version.json
	sed -i "s,DOWNLOADLOCATION,$RELEASE_NAME\/Preside-$VERSION_NUMBER.zip," box.json

	echo "";
	echo "Zipping up project...";
	echo "";

	zip -rq $ZIP_FILE * -x jmimemagic.log || exit 1
else
	echo "Skipping packaging, not on stable or release branch in a travis build."
	exit 0
fi

echo "";
echo "All done :)";
echo "";

exit 0;
