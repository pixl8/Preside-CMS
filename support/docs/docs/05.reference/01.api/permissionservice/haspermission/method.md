---
id: "permissionservice-haspermission"
title: "hasPermission()"
---


## Overview




```luceescript
public boolean function hasPermission(
      required string permissionKey
    ,          string context       = ""
    ,          array  contextKeys  
    ,          string userId        = ID of logged in user
)
```

Returns whether or not the user has permission to the given
set of keys.


See [[cmspermissioning]] for a full guide to CMS users and permissions.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>permissionKey</td><td>string</td><td>Yes</td><td>The permission key as defined in `Config.cfc`</td></tr><tr><td>context</td><td>string</td><td>No (default="")</td><td>Optional named context</td></tr><tr><td>contextKeys</td><td>array</td><td>No</td><td>Array of keys for the given context (required if context supplied)</td></tr><tr><td>userId</td><td>string</td><td>No (default=ID of logged in user)</td><td>ID of the user who's permissions we wish to check</td></tr></tbody></table></div>