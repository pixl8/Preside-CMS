---
id: "storageprovider-deleteobject"
title: "deleteObject()"
---


## Overview




```luceescript
public void function deleteObject(
      required string  path   
    ,          boolean trashed
)
```

Permanently deletes the object that resides at the given path.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>path</td><td>string</td><td>Yes</td><td>The path of the stored object</td></tr><tr><td>trashed</td><td>boolean</td><td>No</td><td>Whether or not the object has been "trashed"</td></tr></tbody></table></div>