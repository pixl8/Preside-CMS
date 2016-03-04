---
id: "presiderestconfigurationwrapper-getsetting"
title: "getSetting()"
---


## Overview




```luceescript
public any function getSetting(
      required string name        
    ,          string defaultValue = ""
    ,          string api          = "/"
)
```

Fetches a configuration value from
the configuration based on the currently in use
API and resource

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>name</td><td>string</td><td>Yes</td><td>the name of the setting</td></tr><tr><td>defaultValue</td><td>string</td><td>No (default="")</td><td>the name of the setting</td></tr><tr><td>api</td><td>string</td><td>No (default="/")</td><td></td></tr></tbody></table></div>