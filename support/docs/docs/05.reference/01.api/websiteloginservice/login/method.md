---
id: "websiteloginservice-login"
title: "login()"
---


## Overview




```luceescript
public boolean function login(
      required string  loginId             
    ,          string  password             = ""
    ,          boolean rememberLogin        = false
    ,          any     rememberExpiryInDays = 90
    ,          boolean skipPasswordCheck    = false
)
```

Logs the user in by matching the passed login id against either the login id or email address
fields and running a bcrypt password check to verify the security credentials. Returns true on success, false otherwise.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>loginId</td><td>string</td><td>Yes</td><td>Either the login id or email address of the user to login</td></tr><tr><td>password</td><td>string</td><td>No (default="")</td><td>The password that the user has entered during login</td></tr><tr><td>rememberLogin</td><td>boolean</td><td>No (default=false)</td><td>Whether or not to set a "remember me" cookie</td></tr><tr><td>rememberExpiryInDays</td><td>any</td><td>No (default=90)</td><td>When setting a remember me cookie, how long (in days) before the cookie should expire</td></tr><tr><td>skipPasswordCheck</td><td>boolean</td><td>No (default=false)</td><td></td></tr></tbody></table></div>