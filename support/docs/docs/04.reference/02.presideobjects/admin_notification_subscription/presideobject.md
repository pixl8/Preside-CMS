---
id: "presideobject-admin_notification_subscription"
title: "Notification subscription"
---

## Overview


The notification subscription object is used to store details of a single user's subscriptions to particular notification topics

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  admin_notification_subscription</td></tr><tr><th>Table name</th><td>  psys_admin_notification_subscription</td></tr><tr><th>Path</th><td>  /preside-objects/admin/notifications/admin_notification_subscription.cfc</td></tr></table></div>

## Properties


```luceescript
property name="security_user"           required=true  uniqueindexes="notificationSubscriber|1" relationship="many-to-one"  ondelete="cascade";
property name="topic"                   required=true  uniqueindexes="notificationSubscriber|2" type="string" dbtype="varchar" maxlength=100 indexes="topic";
property name="get_email_notifications" required=false type="boolean" dbtype="boolean" indexes="emailnotifiers" default=false;
```