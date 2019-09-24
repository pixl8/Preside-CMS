#!/bin/bash

cd `dirname $0`
CWD="`pwd`"
NOW="`date`"

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
		BUILD_NUMBER=`printf %07d $TRAVIS_BUILD_NUMBER`
		VERSION_NUMBER="${TRAVIS_TAG//v}+${BUILD_NUMBER}"
		ZIP_FILE_NAME="Preside-${TRAVIS_TAG//v}-${BUILD_NUMBER}.zip"
		RELEASE_NAME="stable"
	elif [[ $TRAVIS_BRANCH == release* ]] ; then
		VERSION_NUMBER="${TRAVIS_BRANCH//release-}-SNAPSHOT${TRAVIS_BUILD_NUMBER}"
		ZIP_FILE_NAME="Preside-${TRAVIS_BRANCH//release-}-SNAPSHOT${TRAVIS_BUILD_NUMBER}.zip"
		RELEASE_NAME="bleeding-edge"
	else
		VERSION_NUMBER="unknown"
		ZIP_FILE_NAME="Preside-unknown.zip"
	fi

	echo "Packaging application ${VERSION_NUMBER}...";
	echo "";
	echo "";

	PACKAGE_DIR="${CWD}/package"
	ARTIFACTS_DIR="${CWD}/artifacts/${RELEASE_NAME}"
	ZIP_FILE="${ARTIFACTS_DIR}/${ZIP_FILE_NAME}"

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

	sed -i "s,VERSION_NUMBER,$VERSION_NUMBER," box.json
	sed -i "s,VERSION_NUMBER,$VERSION_NUMBER," version.json
	sed -i "s,VERSION_NUMBER,$VERSION_NUMBER," system/config/Config.cfc
	sed -i "s,DOWNLOADLOCATION,$RELEASE_NAME\/${ZIP_FILE_NAME}," box.json

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
