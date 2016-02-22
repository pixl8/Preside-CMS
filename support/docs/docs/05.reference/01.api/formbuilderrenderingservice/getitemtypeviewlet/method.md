---
id: "formbuilderrenderingservice-getitemtypeviewlet"
title: "getItemTypeViewlet()"
---


## Overview




```luceescript
public string function getItemTypeViewlet(
      required string itemType
    , required string context 
)
```

Returns the convention based viewlet name
for the given item type and context

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>itemType</td><td>string</td><td>Yes</td><td>The item type who's viewlet you wish to get</td></tr><tr><td>context</td><td>string</td><td>Yes</td><td>The context in which the item will be rendered. i.e. 'input', 'adminPlaceholder', 'response', etc.</td></tr></tbody></table></div>