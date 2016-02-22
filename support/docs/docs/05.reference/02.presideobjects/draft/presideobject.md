---
id: "presideobject-draft"
title: "Draft"
---

## Overview


The draft object represents any draft data that is stored against a specific [[presideobject-security_user]].

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  draft</td></tr><tr><th>Table name</th><td>  psys_draft</td></tr><tr><th>Path</th><td>  /preside-objects/core/draft.cfc</td></tr></table></div>

## Properties


```luceescript
property name="key" type="string"  dbtype="varchar" maxlength="200"        required="true" uniqueindexes="userdraft|1";
property name="owner" relationship="many-to-one" relatedTo="security_user" required="true" uniqueindexes="userdraft|2" control="none";
property name="content" type="string" dbtype="longtext" required="false";
```