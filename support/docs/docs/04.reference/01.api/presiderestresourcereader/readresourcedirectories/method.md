---
id: "presiderestresourcereader-readresourcedirectories"
title: "readResourceDirectories()"
---


## Overview




```luceescript
public struct function readResourceDirectories(
      required array directories
)
```

Scans passed directories for resources and returns
prepared arrays of resource metadata, grouped by API, that the
platform can use to route REST requests

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>directories</td><td>array</td><td>Yes</td><td>array of mapped directory paths</td></tr></tbody></table></div>