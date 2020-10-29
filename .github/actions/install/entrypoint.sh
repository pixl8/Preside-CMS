#!/bin/bash

cd $GITHUB_WORKSPACE

box install --force save=false || exit 1;
rm -rf ./system/externals/lucee-spreadsheet/javaLoader;
rm -rf ./system/externals/lucee-spreadsheet/test;
rm -rf ./system/externals/cfconcurrent/javaloader;

cd ./system/assets
npm install || exit 1
grunt all || exit 1

cd $GITHUB_WORKSPACE