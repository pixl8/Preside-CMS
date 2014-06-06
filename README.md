Preside-CMS
===========

Preside CMS is an open source CMS for the Railo language

Stable Master Branch
[![Build Status](https://travis-ci.org/pixl8/Preside-CMS.svg?branch=master "Stable master branch")](https://travis-ci.org/pixl8/Preside-CMS) 

Bleeding Edge Develop Branch
[![Build Status](https://travis-ci.org/pixl8/Preside-CMS.svg?branch=develop "Bleeding edge develop branch")](https://travis-ci.org/pixl8/Preside-CMS)

#Rough Install guide

* Once we have predownloadable builds and installer some of these steps will be redundant, its coming!
* Get Railo Bleeding edge running 4.2.009 or the RC
* Download PresideCMS and run the ant build process which pulls down dependencies /PresideCMSPath/support/build/local/build.xml
* Setup a railo /preside mapping and point it to the root of your PresideCMS Path

For your sample site
* Setup a DSN called sample_dsn pointing to a MySQL DB (At present the open source version of PresideCMS ships with just a MySQL Adapter other ones can be contributed or may be released later)
* Make sure the root of your site is pointing to the wwwroot folder
