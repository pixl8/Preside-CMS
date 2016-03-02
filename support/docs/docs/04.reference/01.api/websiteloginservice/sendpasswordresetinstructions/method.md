---
id: "websiteloginservice-sendpasswordresetinstructions"
title: "sendPasswordResetInstructions()"
---


## Overview




```luceescript
public boolean function sendPasswordResetInstructions(
      required string loginId
)
```

Sends password reset instructions to the supplied user. Returns true if successful, false otherwise.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>loginId</td><td>string</td><td>Yes</td><td>Either the email address or login id of the user</td></tr></tbody></table></div>