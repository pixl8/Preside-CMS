---
id: "presiderestresponse-setheaders"
title: "setHeaders()"
---


## Overview




```luceescript
public any function setHeaders(
      required struct headers
)
```

Sets headers on the rest response object. Can be called multiple
times to build a greater collection of headers

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>headers</td><td>struct</td><td>Yes</td><td>Structure containing headers where struct keys are header names and values are corresponding header values</td></tr></tbody></table></div>