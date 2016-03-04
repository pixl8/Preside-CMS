---
id: "presidesuperclass-$getnotificationservice"
title: "$getNotificationService()"
---


## Overview




```luceescript
public any function $getNotificationService()
```

Returns an instance of the [[api-notificationservice]]. See [[notifications]] for a full guide.


## Example


```luceescript
var unreadNotifications = $getNotificationService().getUnreadNotificationCount(
        userId = $getAdminLoggedInUserId()
);
```

