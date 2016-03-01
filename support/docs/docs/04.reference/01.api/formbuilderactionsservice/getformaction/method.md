---
id: "formbuilderactionsservice-getformaction"
title: "getFormAction()"
---


## Overview




```luceescript
public struct function getFormAction(
      required string id
)
```

Retuns a form's action from the DB, converted to a useful struct. Keys are
'id', 'action' (a structure containing action configuration) and 'configuration'
(a structure of configuration options for the action)

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>id</td><td>string</td><td>Yes</td><td>ID of the action you wish to get</td></tr></tbody></table></div>