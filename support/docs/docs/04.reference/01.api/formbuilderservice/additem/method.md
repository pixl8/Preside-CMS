---
id: "formbuilderservice-additem"
title: "addItem()"
---


## Overview




```luceescript
public string function addItem(
      required string formId       
    , required string itemType     
    , required struct configuration
)
```

Adds a new item to the form. Returns the ID of the
newly generated item

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formId</td><td>string</td><td>Yes</td><td>ID of the form to which to add the new item</td></tr><tr><td>itemType</td><td>string</td><td>Yes</td><td>ID of the item type, e.g. 'content' or 'textarea', etc.</td></tr><tr><td>configuration</td><td>struct</td><td>Yes</td><td>Structure of configuration options for the item</td></tr></tbody></table></div>