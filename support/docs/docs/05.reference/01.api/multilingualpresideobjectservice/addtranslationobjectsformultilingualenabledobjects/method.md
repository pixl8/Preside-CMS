---
id: "multilingualpresideobjectservice-addtranslationobjectsformultilingualenabledobjects"
title: "addTranslationObjectsForMultilingualEnabledObjects()"
---


## Overview




```luceescript
public void function addTranslationObjectsForMultilingualEnabledObjects(
      required struct objects
)
```

Performs the magic of creating extra database tables (preside objects) to store the
translations of multilingual enabled objects.

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objects</td><td>struct</td><td>Yes</td><td>Objects as compiled and read by the preside object service.</td></tr></tbody></table></div>