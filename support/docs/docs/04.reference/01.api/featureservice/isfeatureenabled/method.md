---
id: "featureservice-isfeatureenabled"
title: "isFeatureEnabled()"
---


## Overview




```luceescript
public boolean function isFeatureEnabled(
      required string feature     
    ,          string siteTemplate
)
```

Returns whether or not the passed feature is currently enabled

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>feature</td><td>string</td><td>Yes</td><td>name of the feature to check</td></tr><tr><td>siteTemplate</td><td>string</td><td>No</td><td>current active site template - can be used to check features that can be site template specific</td></tr></tbody></table></div>