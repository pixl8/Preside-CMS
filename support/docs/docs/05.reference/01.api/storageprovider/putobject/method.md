---
id: "storageprovider-putobject"
title: "putObject()"
---


## Overview




```luceescript
public void function putObject(
      required any     object 
    , required string  path   
    ,          boolean private
)
```

Puts an object into the store.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>object</td><td>any</td><td>Yes</td><td>Either a full path to a local file on the server, or the binary content of a file</td></tr><tr><td>path</td><td>string</td><td>Yes</td><td>Path in the storage provider at which the object should be stored</td></tr><tr><td>private</td><td>boolean</td><td>No</td><td>Whether or not the object should be stored privately</td></tr></tbody></table></div>