---
id: "presidesuperclass-$createnotification"
title: "$createNotification()"
---


## Overview




```luceescript
public any function $createNotification()
```

Proxy to the [[notificationservice-createnotification]] method of the [[api-notificationservice]].
See [[notifications]] for a full guide.


## Example


```luceescript
$createNotification(
          topic = "eventbooked"
        , type  = "info"
        , data  = { bookingId = arguments.bookingId }
);
```

