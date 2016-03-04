---
id: "presidesuperclass-$iswebsiteuserimpersonated"
title: "$isWebsiteUserImpersonated()"
---


## Overview




```luceescript
public any function $isWebsiteUserImpersonated()
```

Proxy to the [[websiteloginservice-isimpersonated]] method of [[api-websiteloginservice]].
See [[websiteusersandpermissioning]] for a full guide.


## Example


```luceescript
if ( $isWebsiteUserLoggedIn() && !$isWebsiteUserImpersonated() ) {
        // do some sensitive action that requires the actual user to be logged in
}
```

