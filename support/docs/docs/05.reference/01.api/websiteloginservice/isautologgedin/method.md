---
id: "websiteloginservice-isautologgedin"
title: "isAutoLoggedIn()"
---


## Overview




```luceescript
public boolean function isAutoLoggedIn()
```

Returns whether or not the user making the current request is only automatically logged in.
This would happen when the user has been logged in via a "remember me" cookie. System's can
make use of this method when protecting pages that require a full authenticated session, forcing
a login prompt when this method returns true.

