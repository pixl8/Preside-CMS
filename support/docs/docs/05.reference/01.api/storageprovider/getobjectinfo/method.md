---
id: "storageprovider-getobjectinfo"
title: "getObjectInfo()"
---


## Overview




```luceescript
public struct function getObjectInfo(
      required string  path   
    ,          boolean trashed
    ,          boolean private
)
```

Returns size and lastmodified information about the object that resides at the provided path.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>path</td><td>string</td><td>Yes</td><td>The path of the stored object</td></tr><tr><td>trashed</td><td>boolean</td><td>No</td><td>Whether or not the object has been "trashed"</td></tr><tr><td>private</td><td>boolean</td><td>No</td><td>Whether or not the object is private</td></tr></tbody></table></div>