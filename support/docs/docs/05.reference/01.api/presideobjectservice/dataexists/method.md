---
id: "presideobjectservice-dataexists"
title: "dataExists()"
---


## Overview




```luceescript
public boolean function dataExists(
      required string objectName
)
```

Returns true if records exist that match the supplied fillter, false otherwise.


>>> In addition to the named arguments here, you can also supply any valid arguments
that can be supplied to the [[presideobjectservice-selectdata]] method


## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>Name of the object in which the records may or may not exist</td></tr></tbody></table></div>


## Example


```luceescript
eventsExist = presideObjectService.dataExists(
      objectName = "event"
    , filter     = { category = rc.category }
);
```