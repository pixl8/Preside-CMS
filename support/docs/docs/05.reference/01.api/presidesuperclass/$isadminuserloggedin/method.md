---
id: "presidesuperclass-$isadminuserloggedin"
title: "$isAdminUserLoggedIn()"
---


## Overview




```luceescript
public any function $isAdminUserLoggedIn()
```

Proxy to the [[loginservice-isLoggedIn]] method of [[api-loginservice]].
See [[cmspermissioning]] for a full guide.


## Example


```luceescript
if ( $isAdminUserLoggedIn() ) {
        // ...
}
```

