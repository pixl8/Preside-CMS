---
id: "storageprovider-getobject"
title: "getObject()"
---


## Overview




```luceescript
public binary function getObject(
      required string  path   
    ,          boolean trashed
)
```

Returns the binary data of the object that lives at the given path.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>path</td><td>string</td><td>Yes</td><td>The path of the stored object</td></tr><tr><td>trashed</td><td>boolean</td><td>No</td><td>Whether or not the object has been "trashed"</td></tr></tbody></table></div>