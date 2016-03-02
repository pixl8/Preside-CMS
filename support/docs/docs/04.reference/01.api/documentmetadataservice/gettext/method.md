---
id: "documentmetadataservice-gettext"
title: "getText()"
---


## Overview




```luceescript
public string function getText(
      required any fileContent
)
```

This method returns raw text read from the document, useful for populating search engines, etc.
This method is currently unsupported in the core PresideCMS platform and must be supported
through Apache Tika extension or similar.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>fileContent</td><td>any</td><td>Yes</td><td>Binary content of the file for which you want to extract meta data</td></tr></tbody></table></div>