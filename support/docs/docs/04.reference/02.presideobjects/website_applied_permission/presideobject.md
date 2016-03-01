---
id: "presideobject-website_applied_permission"
title: "Website applied permission"
---

## Overview


A website applied permission records a grants or deny permission for a given user or benefit, permission key and optional context.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  website_applied_permission</td></tr><tr><th>Table name</th><td>  psys_website_applied_permission</td></tr><tr><th>Path</th><td>  /preside-objects/websiteUserManagement/website_applied_permission.cfc</td></tr></table></div>

## Properties


```luceescript
property name="permission_key" type="string"  dbtype="varchar" maxlength="100" required=true  uniqueindexes="context_permission|1";
property name="granted"        type="boolean" dbtype="boolean"                 required=true;

property name="context"        type="string"  dbtype="varchar" maxlength="100" required=false uniqueindexes="context_permission|2";
property name="context_key"    type="string"  dbtype="varchar" maxlength="100" required=false uniqueindexes="context_permission|3";

property name="benefit" relationship="many-to-one" relatedto="website_benefit" required=false uniqueindexes="context_permission|4" ondelete="cascade";
property name="user"    relationship="many-to-one" relatedto="website_user"    required=false uniqueindexes="context_permission|5" ondelete="cascade";

```