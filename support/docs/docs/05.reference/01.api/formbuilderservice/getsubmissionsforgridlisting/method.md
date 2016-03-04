---
id: "formbuilderservice-getsubmissionsforgridlisting"
title: "getSubmissionsForGridListing()"
---


## Overview




```luceescript
public struct function getSubmissionsForGridListing(
      required string  formId     
    ,          numeric startRow    = 1
    ,          numeric maxRows     = 10
    ,          string  orderBy     = ""
    ,          string  searchQuery = ""
)
```

Returns form submissions in a result format that is ready
for display in grid table

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formId</td><td>string</td><td>Yes</td><td>ID of the form who's submissions you wish to get</td></tr><tr><td>startRow</td><td>numeric</td><td>No (default=1)</td><td>Start row of recordset (for pagination)</td></tr><tr><td>maxRows</td><td>numeric</td><td>No (default=10)</td><td>Max rows to fetch (for pagination)</td></tr><tr><td>orderBy</td><td>string</td><td>No (default="")</td><td>Order by field</td></tr><tr><td>searchQuery</td><td>string</td><td>No (default="")</td><td>Search query with which to filter</td></tr></tbody></table></div>