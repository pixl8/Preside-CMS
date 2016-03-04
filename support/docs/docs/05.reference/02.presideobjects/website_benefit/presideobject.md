---
id: "presideobject-website_benefit"
title: "Website user benefit"
---

## Overview


Website benefits can be tagged against website users (see [[presideobject-website_user]]).
Pages in the site tree, assets in the asset manager, and other custom access areas can then be
tagged with member benefits to control users' access to multiple areas and actions in the site through their benefits.
This is also a useful object to extend so that you could add other types of benefits other than page / asset access. For
example, you could have a disk space field that can tell the system how much disk space a user has in an uploads folder or
some such.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  website_benefit</td></tr><tr><th>Table name</th><td>  psys_website_benefit</td></tr><tr><th>Path</th><td>  /preside-objects/websiteUserManagement/website_benefit.cfc</td></tr></table></div>

## Properties


```luceescript
property name="label" uniqueindexes="benefit_name";
property name="priority"    type="numeric" dbtype="int"                      required=false default="method:calculatePriority";
property name="description" type="string"  dbtype="varchar" maxLength="200"  required=false;

property name="combined_benefits" relationship="many-to-many" relatedTo="website_benefit" relatedVia="website_benefit_combined_benefits";
property name="combined_benefits_are_inclusive" type="boolean" dbtype="boolean" required=false default=false;

```