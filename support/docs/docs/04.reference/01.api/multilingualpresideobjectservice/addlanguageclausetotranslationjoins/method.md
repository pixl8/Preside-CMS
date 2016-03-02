---
id: "multilingualpresideobjectservice-addlanguageclausetotranslationjoins"
title: "addLanguageClauseToTranslationJoins()"
---


## Overview




```luceescript
public void function addLanguageClauseToTranslationJoins(
      required array  tableJoins    
    , required string language      
    , required struct preparedFilter
)
```

Works on intercepted select queries to discover and decorate
joins on translation objects with an additional clause for the
passed in language

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>tableJoins</td><td>array</td><td>Yes</td><td>Array of table joins as calculated by the SelectData() logic</td></tr><tr><td>language</td><td>string</td><td>Yes</td><td>The language to filter on</td></tr><tr><td>preparedFilter</td><td>struct</td><td>Yes</td><td>The fully prepared and resolved filter that will be used in the select query</td></tr></tbody></table></div>