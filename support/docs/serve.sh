#!/bin/bash

cd `dirname $0`
CWD="`pwd`"

box start name=presidedocslocalserver directory=$CWD/server/ force=true rewritesEnable=true rewritesConfig=$CWD/server/urlrewrite.xml port=4141 trayIcon=$CWD/luceelogoicon.png
