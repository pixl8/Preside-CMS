---
id: "multilingualpresideobjectservice-getlanguage"
title: "getLanguage()"
---


## Overview




```luceescript
public struct function getLanguage(
      required string languageId
)
```

Returns a structure of language details for the given language.
If the language is not an actively translatable language,
an empty structure will be returned.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>languageId</td><td>string</td><td>Yes</td><td>ID of the language to get</td></tr></tbody></table></div>