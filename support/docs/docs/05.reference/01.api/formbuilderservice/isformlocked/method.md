---
id: "formbuilderservice-isformlocked"
title: "isFormLocked()"
---


## Overview




```luceescript
public boolean function isFormLocked(
      string formid = ""
    , string itemId = ""
)
```

Returns whether or not the given form is locked
for editing.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>formid</td><td>string</td><td>No (default="")</td><td>ID of the form you want to check. Required if 'itemId' not supplied.</td></tr><tr><td>itemId</td><td>string</td><td>No (default="")</td><td>ID of the form you want to check. Required if 'id' not supplied</td></tr></tbody></table></div>