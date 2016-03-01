---
id: "presiderestresponse-seterror"
title: "setError()"
---


## Overview




```luceescript
public any function setError(
      string  type           = "rest.server.error"
    , string  title          = "Server error"
    , numeric errorCode      = 500
    , string  message        = "An unhandled exception occurred within the REST API"
    , string  detail         = ""
    , struct  additionalInfo
)
```

Sets data, statuses and headers based on common arguments
for errors

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>type</td><td>string</td><td>No (default="rest.server.error")</td><td></td></tr><tr><td>title</td><td>string</td><td>No (default="Server error")</td><td></td></tr><tr><td>errorCode</td><td>numeric</td><td>No (default=500)</td><td></td></tr><tr><td>message</td><td>string</td><td>No (default="An unhandled exception occurred within the REST API")</td><td></td></tr><tr><td>detail</td><td>string</td><td>No (default="")</td><td></td></tr><tr><td>additionalInfo</td><td>struct</td><td>No</td><td></td></tr></tbody></table></div>