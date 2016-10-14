---
id: "presideobject-multilingual_language"
title: "Multilingual language"
---

## Overview


The multilingual language object stores
languages that can be available to the Presides core
multilingual content system

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  multilingual_language</td></tr><tr><th>Table name</th><td>  psys_multilingual_language</td></tr><tr><th>Path</th><td>  /preside-objects/i18n/multilingual_language.cfc</td></tr></table></div>

## Properties


```luceescript
property name="name"          type="string"  dbtype="varchar" maxlength=200 required=true  uniqueindexes="language_name" control="textinput";
property name="iso_code"      type="string"  dbtype="varchar" maxlength=5   required=true  uniqueindexes="iso_code" format="languageCode";
property name="slug"          type="string"  dbtype="varchar" maxlength=5   required=false uniqueindexes="slug"     format="slug";
property name="native_name"   type="string"  dbtype="varchar" maxlength=200 required=true control="textinput";
property name="right_to_left" type="boolean" dbtype="boolean"               required=false default=false;
```