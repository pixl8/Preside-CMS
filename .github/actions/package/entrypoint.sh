#!/bin/bash

RELEASE_VERSION=$INPUT_RELEASE_VERSION
IS_SNAPSHOT=$INPUT_IS_SNAPSHOT
ZIP_FILE_NAME="Preside-${RELEASE_VERSION}.zip"
NOW="`date`"

if [[ $RELEASE_VERSION == "0.0.0-DEMO"* ]] ; then
	RELEASE_NAME="demo"
elif [[ "${IS_SNAPSHOT}" == "false" ]] ; then
	RELEASE_NAME="stable"
else
	RELEASE_NAME="bleeding-edge"
fi

echo "Packaging application ${RELEASE_VERSION}...";
echo "";
echo "";

PACKAGE_DIR="${GITHUB_WORKSPACE}/package"
ARTIFACTS_DIR="${GITHUB_WORKSPACE}/artifacts/${RELEASE_NAME}"
ZIP_FILE="${ARTIFACTS_DIR}/${ZIP_FILE_NAME}"

mkdir -p $PACKAGE_DIR
mkdir -p $ARTIFACTS_DIR

rsync -a ${GITHUB_WORKSPACE}/ --exclude=".*" --exclude="/package" --exclude="/artifacts" --exclude="*.sh" --exclude="/tests"  --exclude="/system/assets/node_modules" --exclude="zanata.xml" "$PACKAGE_DIR" || exit 1

cd $PACKAGE_DIR

echo "";
echo "Setting up version files, etc..."
echo "";

echo '{ "version":"VERSION_NUMBER" }' > version.json
echo Built on: $NOW > "Preside-$RELEASE_VERSION-$RELEASE_NAME.txt"

rm box.json
cp /box.json box.json

sed -i "s,VERSION_NUMBER,$RELEASE_VERSION," box.json
sed -i "s,VERSION_NUMBER,$RELEASE_VERSION," version.json
sed -i "s,VERSION_NUMBER,$RELEASE_VERSION," system/config/Config.cfc
sed -i "s,DOWNLOADLOCATION,$RELEASE_NAME\/${ZIP_FILE_NAME}," box.json

cp box.json ${GITHUB_WORKSPACE}/box.json

echo "";
echo "Zipping up project...";
echo "";

zip -rq $ZIP_FILE * -x jmimemagic.log || exit 1

echo "Uploading to https://downloads.preside.org/${RELEASE_NAME}/${ZIP_FILE_NAME} ..."
aws s3 cp --acl=public-read $ZIP_FILE s3://downloads.preside.org/${RELEASE_NAME}/${ZIP_FILE_NAME}

echo "::set-output name=artifact_path::artifacts/${RELEASE_NAME}/${ZIP_FILE_NAME}"
echo "::set-output name=artifact_remote_path::${RELEASE_NAME}/${ZIP_FILE_NAME}"
echo "::set-output name=artifact_name::${ZIP_FILE_NAME}"

echo "";
echo "All done :)";
echo "";

exit 0;
