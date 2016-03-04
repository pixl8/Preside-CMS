---
id: "presideobject-admin_notification_consumer"
title: "Notification consumer"
---

## Overview


The notification consumer object is used to store details of a single user's interactions with a notification

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  admin_notification_consumer</td></tr><tr><th>Table name</th><td>  psys_admin_notification_consumer</td></tr><tr><th>Path</th><td>  /preside-objects/admin/notifications/admin_notification_consumer.cfc</td></tr></table></div>

## Properties


```luceescript
property name="admin_notification" relationship="many-to-one" required=true uniqueindexes="notificationUser|1" ondelete="cascade";
property name="security_user"      relationship="many-to-one" required=true uniqueindexes="notificationUser|2" ondelete="cascade";

property name="read" type="boolean" dbtype="boolean" required=false default=false indexes="read";
```