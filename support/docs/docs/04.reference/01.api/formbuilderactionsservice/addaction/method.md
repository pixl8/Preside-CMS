---
id: "formbuilderactionsservice-addaction"
title: "addAction()"
---


## Overview




```luceescript
public string function addAction(
      required string formId       
    , required string action       
    , required struct configuration
)
```

Adds a new action to the form. Returns the ID of the
newly generated action

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formId</td><td>string</td><td>Yes</td><td>ID of the form to which to add the new item</td></tr><tr><td>action</td><td>string</td><td>Yes</td><td>ID of the action, e.g. 'email' or 'webhook', etc.</td></tr><tr><td>configuration</td><td>struct</td><td>Yes</td><td>Structure of configuration options for the action</td></tr></tbody></table></div>