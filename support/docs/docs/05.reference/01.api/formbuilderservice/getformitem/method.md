---
id: "formbuilderservice-getformitem"
title: "getFormItem()"
---


## Overview




```luceescript
public struct function getFormItem(
      required string id
)
```

Retuns a form's item from the DB, converted to a useful struct. Keys are
'id', 'type' (a structure containing type configuration) and 'configuration'
(a structure of configuration options for the item)

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>id</td><td>string</td><td>Yes</td><td>ID of the item you wish to get</td></tr></tbody></table></div>