---
id: "formbuilderrenderingservice-getitemtypeexportcolumns"
title: "getItemTypeExportColumns()"
---


## Overview




```luceescript
public array function getItemTypeExportColumns(
      required string itemType     
    , required struct configuration
)
```

Returns an array of column names that the item type will need when rendering
and excel export of responses.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>itemType</td><td>string</td><td>Yes</td><td>The item type, e.g. 'select'</td></tr><tr><td>configuration</td><td>struct</td><td>Yes</td><td>The stored configuration options for the item within the form</td></tr></tbody></table></div>