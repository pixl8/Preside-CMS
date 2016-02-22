---
id: "assetrendererservice-renderasset"
title: "renderAsset()"
---


## Overview




```luceescript
public string function renderAsset(
      required string assetId
    ,          string context = "default"
    ,          struct args    = {}
)
```

Renders a given asset in an optional context. See [[assetmanager]] for more detailed documentation on working with assets.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>assetId</td><td>string</td><td>Yes</td><td>The ID of the asset record to render</td></tr><tr><td>context</td><td>string</td><td>No (default="default")</td><td>The context in which the asset should be rendered. This will inform the choice of viewlet used to render the asset.</td></tr><tr><td>args</td><td>struct</td><td>No (default={})</td><td>Arbitrary args struct to be passed to the viewlet that will render this asset</td></tr></tbody></table></div>