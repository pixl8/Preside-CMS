---
id: "notificationservice-userhasaccesstotopic"
title: "userHasAccessToTopic()"
---


## Overview




```luceescript
public boolean function userHasAccessToTopic(
      required string userId
    , required string topic 
)
```

Returns whether or not the user has access to the given topic

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>userId</td><td>string</td><td>Yes</td><td>ID of the user who's permissions we wish to check</td></tr><tr><td>topic</td><td>string</td><td>Yes</td><td>ID of the topic to check</td></tr></tbody></table></div>