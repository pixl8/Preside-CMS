#!/bin/bash

cd `dirname $0`
CWD="`pwd`"
echo "Building documentation with Lucee :)"

box $CWD/build.cfm
if [ -f .exitcode ]; then
  exitcode=$(<.exitcode)
  rm -f .exitcode
  echo "Exiting build, documentation build failed."
  exit $exitcode
fi

echo "Building complete"
if [[ $TRAVIS_TAG == v* ]] ; then
  echo "Zipping up docs for offline download..."
  cd builds/html
  zip -q -r presidecms-docs.zip *
  cd ../../
  echo "Zipped."
  echo "Preparing dash artifacts..."
  cp -r builds/html builds/artifacts
  mkdir builds/artifacts/dash
  cp builds/dash/presidecms.xml builds/artifacts/dash/
  cd builds/dash
  tar -czf ../../builds/artifacts/dash/presidecms.tgz presidecms.docset
  cd ../../
  echo "Prepared."
  echo "Syncing with S3..."
  s3_website push
  echo "All done :)"
fi
