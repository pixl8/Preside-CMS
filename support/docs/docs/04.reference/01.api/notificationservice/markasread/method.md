---
id: "notificationservice-markasread"
title: "markAsRead()"
---


## Overview




```luceescript
public numeric function markAsRead(
      required array  notificationIds
    , required string userId         
)
```

Marks notifications as read for a given user

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>notificationIds</td><td>array</td><td>Yes</td><td>Array of notification IDs to mark as read</td></tr><tr><td>userId</td><td>string</td><td>Yes</td><td>The id of the user to mark as read for</td></tr></tbody></table></div>