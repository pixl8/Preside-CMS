---
id: "multilingualpresideobjectservice-createtranslationobject"
title: "createTranslationObject()"
---


## Overview




```luceescript
public struct function createTranslationObject(
      required string objectName  
    , required struct sourceObject
)
```

Returns the meta data for our auto generated translation object based on a given
source object

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>The name of the source object</td></tr><tr><td>sourceObject</td><td>struct</td><td>Yes</td><td>The metadata of the source object</td></tr></tbody></table></div>