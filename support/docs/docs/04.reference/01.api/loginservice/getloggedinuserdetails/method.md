---
id: "loginservice-getloggedinuserdetails"
title: "getLoggedInUserDetails()"
---


## Overview




```luceescript
public struct function getLoggedInUserDetails()
```

Returns a structure of user details of the
currently logged in CMS admin user.
The structure will contain a key for every property in
the [[presideobject-security_user]] object.
If no user is logged in, an empty structure will be returned.


See [[cmspermissioning]] for a full guide to CMS admin users.

