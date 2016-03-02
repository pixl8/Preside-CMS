---
id: "storageprovider-objectexists"
title: "objectExists()"
---


## Overview




```luceescript
public boolean function objectExists(
      required string  path   
    ,          boolean trashed
)
```

Returns whether or not an object exists for the passed path.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>path</td><td>string</td><td>Yes</td><td>Expected path of the object</td></tr><tr><td>trashed</td><td>boolean</td><td>No</td><td>Whether or not the object has been "trashed"</td></tr></tbody></table></div>