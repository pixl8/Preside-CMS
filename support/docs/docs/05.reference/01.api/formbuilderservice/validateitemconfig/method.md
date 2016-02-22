---
id: "formbuilderservice-validateitemconfig"
title: "validateItemConfig()"
---


## Overview




```luceescript
public any function validateItemConfig(
      required string formId  
    , required string itemType
    , required struct config  
    ,          string itemId   = ""
)
```

Validates the configuration for an item within a form. Returns
a Preside validation result object.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formId</td><td>string</td><td>Yes</td><td>ID of the form to which the item belongs / will belong</td></tr><tr><td>itemType</td><td>string</td><td>Yes</td><td>Type of the form item, e.g. 'textinput', 'content', etc.</td></tr><tr><td>config</td><td>struct</td><td>Yes</td><td>Configuration struct to validate</td></tr><tr><td>itemId</td><td>string</td><td>No (default="")</td><td>ID of the form item, should it already exist</td></tr></tbody></table></div>