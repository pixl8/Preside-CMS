---
id: "presidesuperclass-$getwebsiteloginservice"
title: "$getWebsiteLoginService()"
---


## Overview




```luceescript
public any function $getWebsiteLoginService()
```

Returns the [[api-websiteloginservice]]. This can be used to check logged in user details, etc.
See [[websiteusersandpermissioning]] for a full guide.


## Example


```luceescript
if ( $getWebsiteLoginService().isImpersonated() ) {
        // ...
}
```

