---
id: "presideobject-admin_notification"
title: "Notification"
---

## Overview


The notification object is used to store notifications that can be consumed by admin users

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  admin_notification</td></tr><tr><th>Table name</th><td>  psys_admin_notification</td></tr><tr><th>Path</th><td>  /preside-objects/admin/notifications/admin_notification.cfc</td></tr></table></div>

## Properties


```luceescript
property name="topic"     type="string"  dbtype="varchar" maxlength=200 required=true indexes="topic,topicTypeData|1";
property name="type"      type="string"  dbtype="varchar" maxlength=10  required=true indexes="type,topicTypeData|2";
property name="data"      type="string"  dbtype="text"                  required=false;
property name="data_hash" type="string"  dbtype="varchar" maxlength=32  required=false indexes="topicTypeData|3";
```