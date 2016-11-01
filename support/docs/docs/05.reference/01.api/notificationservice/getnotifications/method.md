---
id: "notificationservice-getnotifications"
title: "getNotifications()"
---


## Overview




```luceescript
public query function getNotifications(
      required string  userId  
    ,          string  topic    = ""
    ,          string  dateFrom = ""
    ,          string  dateTo   = ""
    ,          numeric startRow = 1
    ,          numeric maxRows  = 10
    ,          string  orderBy  = ""
)
```

Returns the latest unread notifications for the given user id. Returns an array of structs, each struct contains id and data keys.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>userId</td><td>string</td><td>Yes</td><td>id of the admin user who's unread notifications we wish to retrieve</td></tr><tr><td>topic</td><td>string</td><td>No (default="")</td><td></td></tr><tr><td>dateFrom</td><td>string</td><td>No (default="")</td><td></td></tr><tr><td>dateTo</td><td>string</td><td>No (default="")</td><td></td></tr><tr><td>startRow</td><td>numeric</td><td>No (default=1)</td><td></td></tr><tr><td>maxRows</td><td>numeric</td><td>No (default=10)</td><td>maximum number of notifications to retrieve</td></tr><tr><td>orderBy</td><td>string</td><td>No (default="")</td><td></td></tr></tbody></table></div>