---
id: "presideobject-audit_log"
title: "Audit log"
---

## Overview


The audit log object is used to store audit trail logs that are triggered by user actions in the administrator (or any other actions you wish to track).

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  audit_log</td></tr><tr><th>Table name</th><td>  psys_audit_log</td></tr><tr><th>Path</th><td>  /preside-objects/admin/audit/audit_log.cfc</td></tr></table></div>

## Properties


```luceescript
property name="detail"     type="string"  dbtype="varchar" maxLength="200" required=true;
property name="source"     type="string"  dbtype="varchar" maxLength="100" required=true;
property name="action"     type="string"  dbtype="varchar" maxLength="100" required=true;
property name="type"       type="string"  dbtype="varchar" maxLength="100" required=true;
property name="instance"   type="string"  dbtype="varchar" maxLength="200" required=true;
property name="uri"        type="string"  dbtype="varchar" maxLength="255" required=true;
property name="user_ip"    type="string"  dbtype="varchar" maxLength="255" required=true;
property name="user_agent" type="string"  dbtype="varchar" maxLength="255" required=false;

property name="user" relationship="many-to-one" relatedTo="security_user" required="true";

property name="datecreated" indexes="logged"; // add a DB index to the default 'datecreated' property
```