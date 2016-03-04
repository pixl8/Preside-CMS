---
id: "websiteloginservice-doesloggedinuserhavebenefits"
title: "doesLoggedInUserHaveBenefits()"
---


## Overview




```luceescript
public boolean function doesLoggedInUserHaveBenefits(
      required array benefits
)
```

Returns true / false depending on whether or not a user has access to any of the supplied benefits

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>benefits</td><td>array</td><td>Yes</td><td>Array of benefit IDs. If the logged in user has any of these benefits, the method will return true</td></tr></tbody></table></div>