---
id: "systemconfigurationservice-getcategorysettings"
title: "getCategorySettings()"
---


## Overview




```luceescript
public struct function getCategorySettings(
      required string  category          
    ,          boolean includeDefaults    = true
    ,          boolean globalDefaultsOnly = false
    ,          string  siteId            
)
```

Returns all the saved settings for a given category.
See [[editablesystemsettings]] for a full guide.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>category</td><td>string</td><td>Yes</td><td>The name of the category who's settings you wish to get</td></tr><tr><td>includeDefaults</td><td>boolean</td><td>No (default=true)</td><td>Whether to include default global and injected settings or whether to just return the settings for the current site</td></tr><tr><td>globalDefaultsOnly</td><td>boolean</td><td>No (default=false)</td><td>Whether to only include default global and injected settings or whether to include all amalgamated settings</td></tr><tr><td>siteId</td><td>string</td><td>No</td><td></td></tr></tbody></table></div>