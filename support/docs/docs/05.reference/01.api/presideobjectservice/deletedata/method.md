---
id: "presideobjectservice-deletedata"
title: "deleteData()"
---


## Overview




```luceescript
public numeric function deleteData(
      required string  objectName    
    ,          string  id            
    ,          any     filter        
    ,          struct  filterParams  
    ,          array   extraFilters  
    ,          array   savedFilters  
    ,          boolean forceDeleteAll = false
)
```

Deletes records from the database. Returns the number of records deleted.


## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>Name of the object from who's database table records are to be deleted</td></tr><tr><td>id</td><td>string</td><td>No</td><td>ID of a record to delete</td></tr><tr><td>filter</td><td>any</td><td>No</td><td>Filter for records to delete, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`</td></tr><tr><td>filterParams</td><td>struct</td><td>No</td><td>Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`</td></tr><tr><td>extraFilters</td><td>array</td><td>No</td><td>An array of extra sets of filters. Each array should contain a structure with :code:`filter` and optional `code:`filterParams` keys.</td></tr><tr><td>savedFilters</td><td>array</td><td>No</td><td></td></tr><tr><td>forceDeleteAll</td><td>boolean</td><td>No (default=false)</td><td>If no id or filter supplied, this must be set to **true** in order for the delete to process</td></tr></tbody></table></div>


## Examples


```luceescript
// delete a single record
deleted = presideObjectService.deleteData(
          objectName = "event"
        , id         = rc.id
);


// delete multiple records using a filter
// (note we are filtering on a column in a related object, "category")
deleted = presideObjectService.deleteData(
          objectName   = "event"
        , filter       = "category.label != :category.label"
        , filterParams = { "category.label" = "BBQs" }
);


// delete all records
// (note we are filtering on a column in a related object, "category")
deleted = presideObjectService.deleteData(
          objectName     = "event"
        , forceDeleteAll = true
);
```