---
id: "websiteloginservice-changepassword"
title: "changePassword()"
---


## Overview




```luceescript
public boolean function changePassword(
      required string  password      
    ,          string  userId        
    ,          boolean changedByAdmin = false
)
```

Changes a password

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>password</td><td>string</td><td>Yes</td><td>The new password</td></tr><tr><td>userId</td><td>string</td><td>No</td><td>ID of the user who's password we wish to change (defaults to currently logged in user id)</td></tr><tr><td>changedByAdmin</td><td>boolean</td><td>No (default=false)</td><td></td></tr></tbody></table></div>