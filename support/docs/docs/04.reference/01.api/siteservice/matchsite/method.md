---
id: "siteservice-matchsite"
title: "matchSite()"
---


## Overview




```luceescript
public struct function matchSite(
      required string domain
    , required string path  
)
```

Returns the site record that matches the incoming domain and URL path.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>domain</td><td>string</td><td>Yes</td><td>The domain name used in the incoming request, e.g. testsite.com</td></tr><tr><td>path</td><td>string</td><td>Yes</td><td>The URL path of the incoming request, e.g. /path/to/somepage.html</td></tr></tbody></table></div>