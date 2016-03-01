---
id: "presideobject-admin_notification_topic"
title: "Notification topic"
---

## Overview


The notification topic object is used to store global configuration for a given notification topic

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  admin_notification_topic</td></tr><tr><th>Table name</th><td>  psys_admin_notification_topic</td></tr><tr><th>Path</th><td>  /preside-objects/admin/notifications/admin_notification_topic.cfc</td></tr></table></div>

## Properties


```luceescript
property name="topic"                 type="string"  dbtype="varchar" maxlength=200 required=true uniqueindex="topic";
property name="send_to_email_address" type="string"  dbtype="text"                  required=false;
property name="save_in_cms"           type="boolean" dbtype="boolean"               required=false default=true;

property name="available_to_groups" relationship="many-to-many" relatedTo="security_group" relatedVia="admin_notification_topic_user_group";
```