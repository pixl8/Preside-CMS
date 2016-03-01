---
id: "presidesuperclass-$getadminpermissionservice"
title: "$getAdminPermissionService()"
---


## Overview




```luceescript
public any function $getAdminPermissionService()
```

Returns the [[api-permissionservice]]. This can be used to check CMS admin permissions, etc.
See [[cmspermissioning]] for a full guide.


## Example


```luceescript
var adminSystemUserRoles = $getAdminPermissionService().listRoles();
```

