---
id: "presidesuperclass-$sendemail"
title: "$sendEmail()"
---


## Overview




```luceescript
public any function $sendEmail()
```

Proxy to the [[emailservice-send]] method of the [[api-emailservice]].
See [[emailtemplating]] for a full guide.


## Example


```luceescript
$sendEmail(
          template = "eventBookingConfirmation"
        , args     =  { bookingId = arguments.bookingId }
);
```

