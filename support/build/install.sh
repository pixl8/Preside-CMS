#!/bin/bash

cd `dirname $0`
cd ../../
CWD="`pwd`"

echo "";
echo "Installing dependencies via box.json...";
echo "";
box install --force save=false || exit 1;
rm -rf ./system/externals/lucee-spreadsheet/javaLoader;
rm -rf ./system/externals/lucee-spreadsheet/test;
rm -rf ./system/externals/cfconcurrent/javaloader;
