---
id: "notificationservice-createnotification"
title: "createNotification()"
---


## Overview




```luceescript
public string function createNotification(
      required string topic
    , required string type 
    , required struct data 
)
```

Adds a notification to the system.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>topic</td><td>string</td><td>Yes</td><td>Topic that indicates the specific notification being raised. e.g. 'sync.jobFailed'</td></tr><tr><td>type</td><td>string</td><td>Yes</td><td>Type of the notification, i.e. 'INFO', 'WARNING' or 'ALERT'</td></tr><tr><td>data</td><td>struct</td><td>Yes</td><td>Supporting data for the notification. This is used, in combination with the topic, to render the alert for the end users.</td></tr></tbody></table></div>