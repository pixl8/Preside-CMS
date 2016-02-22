---
id: "systemconfigurationservice-savesetting"
title: "saveSetting()"
---


## Overview




```luceescript
public any function saveSetting(
      required string category
    , required string setting 
    , required string value   
)
```

Saves the value of a setting.
See [[editablesystemsettings]] for a full guide.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>category</td><td>string</td><td>Yes</td><td>Category name of the setting to save</td></tr><tr><td>setting</td><td>string</td><td>Yes</td><td>Name of the setting to save</td></tr><tr><td>value</td><td>string</td><td>Yes</td><td>Value to save</td></tr></tbody></table></div>