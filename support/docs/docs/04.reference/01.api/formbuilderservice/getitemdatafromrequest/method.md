---
id: "formbuilderservice-getitemdatafromrequest"
title: "getItemDataFromRequest()"
---


## Overview




```luceescript
public any function getItemDataFromRequest(
      required string itemType         
    , required string inputName        
    , required struct requestData      
    , required struct itemConfiguration
)
```

Attempts to retrieve the submitted response for a given item from
the form request, processing any custom preprocessor logic that
is defined for the item type in the process.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>itemType</td><td>string</td><td>Yes</td><td>The type ID of the item</td></tr><tr><td>inputName</td><td>string</td><td>Yes</td><td>The configured input name of the item</td></tr><tr><td>requestData</td><td>struct</td><td>Yes</td><td>The submitted data to the request</td></tr><tr><td>itemConfiguration</td><td>struct</td><td>Yes</td><td>Configuration data associated with the item</td></tr></tbody></table></div>