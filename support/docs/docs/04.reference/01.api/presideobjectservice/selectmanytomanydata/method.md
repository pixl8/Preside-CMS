---
id: "presideobjectservice-selectmanytomanydata"
title: "selectManyToManyData()"
---


## Overview




```luceescript
public query function selectManyToManyData(
      required string objectName  
    , required string propertyName
    ,          array  selectFields
    ,          string orderBy      = ""
)
```

Selects records from many-to-many relationships


>>> You can pass additional arguments to those specified below and they will all be passed to the [[presideobjectservice-selectdata]] method


## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>Name of the object that has the many-to-many property defined</td></tr><tr><td>propertyName</td><td>string</td><td>Yes</td><td>Name of the many-to-many property</td></tr><tr><td>selectFields</td><td>array</td><td>No</td><td>Array of fields to select</td></tr><tr><td>orderBy</td><td>string</td><td>No (default="")</td><td>Plain SQL order by statement</td></tr></tbody></table></div>


## Example


```luceescript
tags = presideObjectService.selectManyToManyData(
          objectName   = "event"
        , propertyName = "tags"
        , orderby      = "tags.label"
);
```