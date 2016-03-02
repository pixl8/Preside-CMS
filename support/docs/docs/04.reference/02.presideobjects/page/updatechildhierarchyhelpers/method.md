---
id: "page-updatechildhierarchyhelpers"
title: "updateChildHierarchyHelpers()"
---


## Overview




```luceescript
public void function updateChildHierarchyHelpers(
      required query  oldData
    , required struct newData
)
```

This method is used internally by the Sitetree Service to ensure
that all child nodes of a page have the most up to date helper fields when the parent node
changes.
This is implemented using some funky SQL that was beyond the capabilities of the standard
Preside Object Service CRUD methods.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>oldData</td><td>query</td><td>Yes</td><td>Query record of the old parent node data</td></tr><tr><td>newData</td><td>struct</td><td>Yes</td><td>Struct containing the changed fields on the parent node</td></tr></tbody></table></div>