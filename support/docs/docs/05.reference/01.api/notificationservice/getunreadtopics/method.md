---
id: "notificationservice-getunreadtopics"
title: "getUnreadTopics()"
---


## Overview




```luceescript
public query function getUnreadTopics(
      required string userId
)
```

Returns counts of unread notifications by topics for the given user

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>userId</td><td>string</td><td>Yes</td><td>id of the admin user who's unread notifications we wish to retrieve</td></tr></tbody></table></div>