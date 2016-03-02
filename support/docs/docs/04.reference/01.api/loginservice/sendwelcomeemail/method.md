---
id: "loginservice-sendwelcomeemail"
title: "sendWelcomeEmail()"
---


## Overview




```luceescript
public boolean function sendWelcomeEmail(
      required string userId        
    , required string createdBy     
    ,          string welcomeMessage = ""
)
```

Sends a welcome email to the given user with password reset instructions

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>userId</td><td>string</td><td>Yes</td><td>ID of the user to send the welcome email to</td></tr><tr><td>createdBy</td><td>string</td><td>Yes</td><td></td></tr><tr><td>welcomeMessage</td><td>string</td><td>No (default="")</td><td>User supplied welcome message</td></tr></tbody></table></div>