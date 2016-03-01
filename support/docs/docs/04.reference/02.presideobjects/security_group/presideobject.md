---
id: "presideobject-security_group"
title: "User group"
---

## Overview


User groups allow you to bulk assign a set of Roles to a number of users.
See [[cmspermissioning]] for more information on users and permissioning.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  security_group</td></tr><tr><th>Table name</th><td>  psys_security_group</td></tr><tr><th>Path</th><td>  /preside-objects/admin/security/security_group.cfc</td></tr></table></div>

## Properties


```luceescript
property name="label" uniqueindexes="role_name";
property name="description"  type="string"  dbtype="varchar" maxLength="200"  required="false";
property name="roles"        type="string"  dbtype="varchar" maxLength="1000" required="false" control="rolepicker" multiple="true";
```