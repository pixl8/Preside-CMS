---
id: "presidesuperclass-$getadminloginservice"
title: "$getAdminLoginService()"
---


## Overview




```luceescript
public any function $getAdminLoginService()
```

Returns the [[api-loginservice]]. This can be used to check logged in user details, etc.
See [[cmspermissioning]] for a full guide.


## Example


```luceescript
if ( $getAdminLoginService().isSystemUser() ) {
        // ...
}
```

