---
id: "presiderestresponse-setstatus"
title: "setStatus()"
---


## Overview




```luceescript
public any function setStatus(
      numeric code
    , string  text
)
```

Sets the status of the response and returns
reference to self so that methods can be chained
allows setting of both code and text for the response.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>code</td><td>numeric</td><td>No</td><td>Numeric status code to set on the response</td></tr><tr><td>text</td><td>string</td><td>No</td><td>Free text status message to return with the response</td></tr></tbody></table></div>