---
id: "loginservice-createloginresettoken"
title: "createLoginResetToken()"
---


## Overview




```luceescript
public struct function createLoginResetToken(
      required string userId
)
```

Creates a login reset token for a user and return a struct with token details.
Struct keys are: resetToken, resetKey and resetExpiry

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>userId</td><td>string</td><td>Yes</td><td>ID of the user to create a reset token for</td></tr></tbody></table></div>