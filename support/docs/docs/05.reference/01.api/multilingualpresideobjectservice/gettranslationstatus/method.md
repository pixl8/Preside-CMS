---
id: "multilingualpresideobjectservice-gettranslationstatus"
title: "getTranslationStatus()"
---


## Overview




```luceescript
public array function getTranslationStatus(
      required string objectName
    , required string recordId  
)
```

Returns an array of actively supported languages as per listLanguages()
with an additional 'status' field indicating the status of the translation
for the given object record

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>Name of the object that has the record we wish to get the translation status of</td></tr><tr><td>recordId</td><td>string</td><td>Yes</td><td>ID of the record we wish to get the translation status of</td></tr></tbody></table></div>