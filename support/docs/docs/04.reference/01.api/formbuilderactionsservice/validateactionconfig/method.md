---
id: "formbuilderactionsservice-validateactionconfig"
title: "validateActionConfig()"
---


## Overview




```luceescript
public any function validateActionConfig(
      required string formId  
    , required string action  
    , required struct config  
    ,          string actionId = ""
)
```

Validates the configuration for an action within a form. Returns
a Preside validation result object.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formId</td><td>string</td><td>Yes</td><td>ID of the form to which the item belongs / will belong</td></tr><tr><td>action</td><td>string</td><td>Yes</td><td>Action name</td></tr><tr><td>config</td><td>struct</td><td>Yes</td><td>Configuration struct to validate</td></tr><tr><td>actionId</td><td>string</td><td>No (default="")</td><td></td></tr></tbody></table></div>