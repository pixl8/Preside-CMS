#!/bin/bash

cd `dirname $0`
CWD="`pwd`"

echo "Welcome to the PresideCMS Test runner and build suite :)";
echo "--------------------------------------------------------";
echo ".";
echo "Building dependencies via box.json";
echo ".";
echo ".";

box install --force

echo ".";
echo ".";
echo "Running tests (please be patient, expect this to take several minutes)...";
echo ".";
echo ".";

./test.sh

echo ".";
echo ".";

./support/docs/build.sh

echo ".";
echo ".";

echo "Packaging up as zip file";
echo ".";
echo ".";

ant -f support/build/build.xml