---
id: "formbuilderservice-getrequestdataforform"
title: "getRequestDataForForm()"
---


## Overview




```luceescript
public struct function getRequestDataForForm(
      required string formId     
    , required struct requestData
)
```

Given incoming request params, returns a structure
containing only the params relevent for the given form

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formId</td><td>string</td><td>Yes</td><td>The ID of the form</td></tr><tr><td>requestData</td><td>struct</td><td>Yes</td><td>A struct containing request data parameters</td></tr></tbody></table></div>