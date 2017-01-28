---
id: "siteservice-getactiveadminsite"
title: "getActiveAdminSite()"
---


## Overview




```luceescript
public struct function getActiveAdminSite(
      required string domain
)
```

Returns the id of the currently active site for the administrator. If no site selected, chooses the first site
that the logged in user has rights to

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>domain</td><td>string</td><td>Yes</td><td>domain that the site should match</td></tr></tbody></table></div>