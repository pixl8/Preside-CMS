---
id: "documentmetadataservice-getmetadata"
title: "getMetaData()"
---


## Overview




```luceescript
public struct function getMetaData(
      required any fileContent
)
```

This method returns any metadata as a cfml structure. This is currently only supported
natively for images. For full support see Pixl8s Apache Tika extension.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>fileContent</td><td>any</td><td>Yes</td><td>Binary content of the file for which you want to extract meta data</td></tr></tbody></table></div>