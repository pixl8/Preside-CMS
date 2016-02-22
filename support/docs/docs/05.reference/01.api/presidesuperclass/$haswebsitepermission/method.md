---
id: "presidesuperclass-$haswebsitepermission"
title: "$hasWebsitePermission()"
---


## Overview




```luceescript
public any function $hasWebsitePermission()
```

Proxy to the [[websiteloginservice-haspermission]] method of [[api-websitepermissionservice]].
See [[websiteusersandpermissioning]] for a full guide.


## Example


```luceescript
if ( $hasWebsitePermission( "review.submit" ) ) {
// ...
}
```

