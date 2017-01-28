---
id: "loginservice-login"
title: "login()"
---


## Overview




```luceescript
public boolean function login(
      required string  loginId             
    , required string  password            
    ,          boolean rememberLogin        = false
    ,          numeric rememberExpiryInDays = 90
)
```

Attempts CMS admin login with login ID and password. Returns true on success,
false otherwise. See [[cmspermissioning]]
for a full guide to CMS admin users.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>loginId</td><td>string</td><td>Yes</td><td>User provided login ID / email address</td></tr><tr><td>password</td><td>string</td><td>Yes</td><td>User provided password</td></tr><tr><td>rememberLogin</td><td>boolean</td><td>No (default=false)</td><td></td></tr><tr><td>rememberExpiryInDays</td><td>numeric</td><td>No (default=90)</td><td></td></tr></tbody></table></div>