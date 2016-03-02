---
id: "systemconfigurationservice-getsetting"
title: "getSetting()"
---


## Overview




```luceescript
public string function getSetting(
      required string category
    , required string setting 
    ,          string default  = ""
)
```

Returns a setting that has been saved.
See [[editablesystemsettings]] for a full guide.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>category</td><td>string</td><td>Yes</td><td>Category name of the setting to get</td></tr><tr><td>setting</td><td>string</td><td>Yes</td><td>Name of the setting to get</td></tr><tr><td>default</td><td>string</td><td>No (default="")</td><td>A default value to return should no value be saved for the setting</td></tr></tbody></table></div>