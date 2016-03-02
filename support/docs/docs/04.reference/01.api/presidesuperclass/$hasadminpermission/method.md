---
id: "presidesuperclass-$hasadminpermission"
title: "$hasAdminPermission()"
---


## Overview




```luceescript
public any function $hasAdminPermission()
```

Proxy to the [[permissionservice-hasadminpermission]] method of [[api-permissionservice]].
See [[cmspermissioning]] for a full guide.


## Example


```luceescript
if ( $hasAdminPermission( "eventssystem.manage" ) ) {
        // ...
}
```

