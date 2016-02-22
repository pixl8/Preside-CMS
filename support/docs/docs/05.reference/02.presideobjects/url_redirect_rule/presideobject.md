---
id: "presideobject-url_redirect_rule"
title: "URL Redirect rule"
---

## Overview


The URL Redirect rule object is used to store individual URL redirect rules. These rules
can use regex, etc. and are used to setup dynamic and editorial redirects.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  url_redirect_rule</td></tr><tr><th>Table name</th><td>  psys_url_redirect_rule</td></tr><tr><th>Path</th><td>  /preside-objects/url_redirect_rule.cfc</td></tr></table></div>

## Properties


```luceescript
property name="label" uniqueindexes="redirectUrlLabel";

property name="source_url_pattern" type="string"  dbtype="varchar" maxlength=200 required=true uniqueindexes="sourceurl";
property name="redirect_type"      type="string"  dbtype="varchar" maxlength=3   required=true format="regex:(301|302)";
property name="exact_match_only"   type="boolean" dbtype="boolean"               required=false default=false;

property name="redirect_to_link" relationship="many-to-one" relatedto="link" required=true;
```