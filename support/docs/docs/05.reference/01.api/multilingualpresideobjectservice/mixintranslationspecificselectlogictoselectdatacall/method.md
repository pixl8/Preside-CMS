---
id: "multilingualpresideobjectservice-mixintranslationspecificselectlogictoselectdatacall"
title: "mixinTranslationSpecificSelectLogicToSelectDataCall()"
---


## Overview




```luceescript
public void function mixinTranslationSpecificSelectLogicToSelectDataCall(
      required string objectName  
    , required array  selectFields
    , required any    adapter     
)
```

Works on intercepted select queries to discover and replace multilingual
select fields with special IfNull( translation, original ) syntax
to automagically select translations without the developer having to
do anything about it

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>The name of the source object</td></tr><tr><td>selectFields</td><td>array</td><td>Yes</td><td>Array of select fields as passed into the presideObjectService.selectData() method</td></tr><tr><td>adapter</td><td>any</td><td>Yes</td><td>Database adapter to be used in generating the select query SQL</td></tr></tbody></table></div>