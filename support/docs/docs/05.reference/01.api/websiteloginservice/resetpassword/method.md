---
id: "websiteloginservice-resetpassword"
title: "resetPassword()"
---


## Overview




```luceescript
public boolean function resetPassword(
      required string token   
    , required string password
)
```

Resets a password by looking up the supplied password reset token and encrypting the supplied password

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>token</td><td>string</td><td>Yes</td><td>The temporary reset password token to look the user up with</td></tr><tr><td>password</td><td>string</td><td>Yes</td><td>The new password</td></tr></tbody></table></div>