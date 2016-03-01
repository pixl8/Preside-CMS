---
id: "formbuilderrenderingservice-getactionviewlet"
title: "getActionViewlet()"
---


## Overview




```luceescript
public string function getActionViewlet(
      required string action 
    , required string context
)
```

Returns the convention based viewlet name
for the given action and context

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>action</td><td>string</td><td>Yes</td><td>The action who's viewlet you wish to get</td></tr><tr><td>context</td><td>string</td><td>Yes</td><td>The context in which the action will be rendered. i.e. 'adminPlaceholder'</td></tr></tbody></table></div>