---
id: "presiderestresourcereader-readresource"
title: "readResource()"
---


## Overview




```luceescript
public array function readResource(
      required string cfcPath
    , required string api    
)
```

Returns an array of REST URI mappings with CFC info
for the given resource CFC (path)

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>cfcPath</td><td>string</td><td>Yes</td><td>Mapped component path to CFC to extract data of</td></tr><tr><td>api</td><td>string</td><td>Yes</td><td>Name of the API to which the resource belongs (e.g. "/myapi/v2")</td></tr></tbody></table></div>