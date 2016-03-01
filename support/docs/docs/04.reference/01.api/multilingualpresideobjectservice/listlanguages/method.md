---
id: "multilingualpresideobjectservice-listlanguages"
title: "listLanguages()"
---


## Overview




```luceescript
public array function listLanguages(
      boolean includeDefault = true
)
```

Returns an array of actively supported languages. Each language
is represented as a struct with id, name, native_name, iso_code and default keys

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>includeDefault</td><td>boolean</td><td>No (default=true)</td><td>Whether or not to include the default language in the array</td></tr></tbody></table></div>