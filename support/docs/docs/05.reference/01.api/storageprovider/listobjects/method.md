---
id: "storageprovider-listobjects"
title: "listObjects()"
---


## Overview




```luceescript
public query function listObjects(
      required string  path   
    ,          boolean private
)
```

Returns a query of objects that live beneath the given path. Query columns should be:
name, path, size and lastmodified.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>path</td><td>string</td><td>Yes</td><td>A path prefix that the method should use when deciding which objects to return. Any object who's path begins with the provide path should be returned.</td></tr><tr><td>private</td><td>boolean</td><td>No</td><td>Whether or not the objects exist in the private store</td></tr></tbody></table></div>