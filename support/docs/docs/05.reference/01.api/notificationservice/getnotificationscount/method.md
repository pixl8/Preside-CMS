---
id: "notificationservice-getnotificationscount"
title: "getNotificationsCount()"
---


## Overview




```luceescript
public numeric function getNotificationsCount(
      required string userId
    ,          string topic  = ""
)
```

Returns the count of non-dismissed notifications for the given user id and optional topic

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>userId</td><td>string</td><td>Yes</td><td>id of the admin user who's unread notifications we wish to retrieve</td></tr><tr><td>topic</td><td>string</td><td>No (default="")</td><td>topic by which to filter the notifications</td></tr></tbody></table></div>