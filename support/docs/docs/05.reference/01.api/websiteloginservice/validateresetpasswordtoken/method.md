---
id: "websiteloginservice-validateresetpasswordtoken"
title: "validateResetPasswordToken()"
---


## Overview




```luceescript
public boolean function validateResetPasswordToken(
      required string token
)
```

Validates a password reset token that has been passed through the URL after
a user has followed 'reset password' link in instructional email.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>token</td><td>string</td><td>Yes</td><td>The token to validate</td></tr></tbody></table></div>