---
id: "notificationservice-saveusersubscriptions"
title: "saveUserSubscriptions()"
---


## Overview




```luceescript
public void function saveUserSubscriptions(
      required string userId
    , required array  topics
)
```

Saves a users subscription preferences

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>userId</td><td>string</td><td>Yes</td><td>ID of the user who's subscribed topics we want to save</td></tr><tr><td>topics</td><td>array</td><td>Yes</td><td>Array of topics to subscribe to</td></tr></tbody></table></div>