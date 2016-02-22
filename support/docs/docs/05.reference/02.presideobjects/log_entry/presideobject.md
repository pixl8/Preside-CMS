---
id: "presideobject-log_entry"
title: "Log entry"
---

## Overview


The log_entry object stores any log entries from logs using the
the PresideDbAppender log appender through logbox.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  log_entry</td></tr><tr><th>Table name</th><td>  psys_log_entry</td></tr><tr><th>Path</th><td>  /preside-objects/core/log_entry.cfc</td></tr></table></div>

## Properties


```luceescript
property name="id"          type="numeric" dbtype="bigint"  generator="increment";
property name="severity"    type="string"  dbtype="varchar" maxLength="20" indexes="severity" required=true;
property name="category"    type="string"  dbtype="varchar" maxLength="50" indexes="category" required=false default="none";
property name="message"     type="string"  dbtype="text";
property name="extra_info"  type="string"  dbtype="text";

property name="admin_user_id" relationship="many-to-one" relatedTo="security_user";
property name="web_user_id"   relationship="many-to-one" relatedTo="website_user";

property name="datemodified" deleted=true;
```