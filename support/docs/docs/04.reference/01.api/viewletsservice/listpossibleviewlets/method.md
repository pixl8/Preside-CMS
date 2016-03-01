---
id: "viewletsservice-listpossibleviewlets"
title: "listPossibleViewlets()"
---


## Overview




```luceescript
public array function listPossibleViewlets(
      string filter = ""
)
```

Returns an array of potential viewlets in the system.
These viewlets will have been calculated by scanning
the handlers and views of the entire application.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>filter</td><td>string</td><td>No (default="")</td><td>A regular expression with which to filter the viewlets to return</td></tr></tbody></table></div>