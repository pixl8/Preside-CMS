---
id: "websiteloginservice-isimpersonated"
title: "isImpersonated()"
---


## Overview




```luceescript
public boolean function isImpersonated()
```

Returns whether or not the user making the current request is only "impersonated" by an admin user.
This method can then be used to hide sensitive information that even admin users impersonating a web
user should not be able to see.

