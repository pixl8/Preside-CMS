---
id: "storageprovider-softdeleteobject"
title: "softDeleteObject()"
---


## Overview




```luceescript
public string function softDeleteObject(
      required string  path   
    ,          boolean private
)
```

"Soft" deletes the object that resides at the given path. This requires
that the impelementing component moves the object to the configured "trash"
storage such that it can be restored later. Must return the trashed path of the object.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>path</td><td>string</td><td>Yes</td><td>The path of the stored object</td></tr><tr><td>private</td><td>boolean</td><td>No</td><td>Whether or not the object is private</td></tr></tbody></table></div>