---
id: "formbuilderservice-isformlocked"
title: "isFormLocked()"
---


## Overview




```luceescript
public boolean function isFormLocked(
      string formid   = ""
    , string itemId   = ""
    , string actionId = ""
)
```

Returns whether or not the given form is locked
for editing.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formid</td><td>string</td><td>No (default="")</td><td>ID of the form you want to check. Required if 'itemId' and 'actionid' not supplied.</td></tr><tr><td>itemId</td><td>string</td><td>No (default="")</td><td>ID of the item that exists within the form you want to check. Required if 'id' and 'actionid' not supplied</td></tr><tr><td>actionId</td><td>string</td><td>No (default="")</td><td>ID of the action that exists within the form you want to check. Required if 'id' and 'itemid' not supplied</td></tr></tbody></table></div>