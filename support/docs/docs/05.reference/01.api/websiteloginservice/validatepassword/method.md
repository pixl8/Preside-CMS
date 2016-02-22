---
id: "websiteloginservice-validatepassword"
title: "validatePassword()"
---


## Overview




```luceescript
public boolean function validatePassword(
      required string password
    ,          string userId  
)
```

Validates the supplied password against the a user (defaults to currently logged in user)

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>password</td><td>string</td><td>Yes</td><td>The user supplied password</td></tr><tr><td>userId</td><td>string</td><td>No</td><td>The id of the user who's password we are to validate. Defaults to the currently logged in user.</td></tr></tbody></table></div>