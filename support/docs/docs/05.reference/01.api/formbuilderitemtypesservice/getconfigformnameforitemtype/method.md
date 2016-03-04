---
id: "formbuilderitemtypesservice-getconfigformnameforitemtype"
title: "getConfigFormNameForItemType()"
---


## Overview




```luceescript
public string function getConfigFormNameForItemType(
      required string itemType
)
```

Returns the configuration form name for the given item
type. If the item type is a form field, this form will
be a combination of the core formfield form + any custom
configuration for the item type itself.
Returns an empty string when not a form field and when
no configuration exists.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>itemType</td><td>string</td><td>Yes</td><td>The item type who's config form name you wish to retrieve</td></tr></tbody></table></div>