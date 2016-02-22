---
id: "presideobject-security_context_permission"
title: "Context permission"
---

## Overview


A context permission records a grant or deny permission for a given user user group, permission key and context.
See [[cmspermissioning]] for more information on permissioning.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  security_context_permission</td></tr><tr><th>Table name</th><td>  psys_security_context_permission</td></tr><tr><th>Path</th><td>  /preside-objects/admin/security/security_context_permission.cfc</td></tr></table></div>

## Properties


```luceescript
property name="permission_key" type="string" dbtype="varchar" maxlength="100" required=true uniqueindexes="context_permission|1";
property name="context"        type="string" dbtype="varchar" maxlength="100" required=true uniqueindexes="context_permission|2";
property name="context_key"    type="string" dbtype="varchar" maxlength="100" required=true uniqueindexes="context_permission|3";
property name="security_group" relationship="many-to-one"                     required=true uniqueindexes="context_permission|4";
property name="granted"        type="boolean" dbtype="boolean" required=true;

```