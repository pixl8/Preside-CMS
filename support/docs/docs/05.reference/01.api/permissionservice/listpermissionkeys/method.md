---
id: "permissionservice-listpermissionkeys"
title: "listPermissionKeys()"
---


## Overview




```luceescript
public array function listPermissionKeys(
      string role   = ""
    , string group  = ""
    , string user   = ""
    , array  filter
)
```

Returns an array of permission keys that apply to the
given arguments.


See [[cmspermissioning]] for a full guide to CMS users and permissions.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>role</td><td>string</td><td>No (default="")</td><td>If supplied, the method will return permission keys that the role has access to</td></tr><tr><td>group</td><td>string</td><td>No (default="")</td><td>If supplied, the method will return permission keys that the group has access to</td></tr><tr><td>user</td><td>string</td><td>No (default="")</td><td>If supplied, the method will return permission keys that the user has access to</td></tr><tr><td>filter</td><td>array</td><td>No</td><td>An array of filters with which to filter permission keys</td></tr></tbody></table></div>