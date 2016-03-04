---
id: "formbuilderservice-renderresponse"
title: "renderResponse()"
---


## Overview




```luceescript
public string function renderResponse(
      required string formId    
    , required string inputName 
    , required string inputValue
)
```

Renders the response for a particular form response

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formId</td><td>string</td><td>Yes</td><td>ID of the form that this response has been submitted against</td></tr><tr><td>inputName</td><td>string</td><td>Yes</td><td>Name of the form item that contains the response</td></tr><tr><td>inputValue</td><td>string</td><td>Yes</td><td>Value of the response</td></tr></tbody></table></div>