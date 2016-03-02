---
id: "presidesuperclass-$getwebsitepermissionservice"
title: "$getWebsitePermissionService()"
---


## Overview




```luceescript
public any function $getWebsitePermissionService()
```

Returns the [[api-websitepermissionservice]]. This can be used to check website user permissions, etc.
See [[websiteusersandpermissioning]] for a full guide.


## Example


```luceescript
var userBenefits = $getWebsitePermissionService().listUserBenefits(
        userId = $getWebsiteLoggedInUserId()
);
```

