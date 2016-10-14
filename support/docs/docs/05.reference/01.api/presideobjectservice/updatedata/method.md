---
id: "presideobjectservice-updatedata"
title: "updateData()"
---


## Overview




```luceescript
public numeric function updateData(
      required string  objectName             
    , required struct  data                   
    ,          string  id                     
    ,          any     filter                 
    ,          struct  filterParams           
    ,          array   extraFilters           
    ,          array   savedFilters           
    ,          boolean forceUpdateAll          = false
    ,          boolean updateManyToManyRecords = false
    ,          boolean isDraft                 = false
    ,          boolean useVersioning           = auto
    ,          numeric versionNumber           = 0
    ,          boolean forceVersionCreation    = false
    ,          boolean setDateModified         = true
)
```

Updates records in the database with a new set of data. Returns the number of records affected by the operation.


## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>Name of the object who's records you want to update</td></tr><tr><td>data</td><td>struct</td><td>Yes</td><td>Structure of data containing new values. Keys should map to properties on the object.</td></tr><tr><td>id</td><td>string</td><td>No</td><td>ID of a single record to update</td></tr><tr><td>filter</td><td>any</td><td>No</td><td>Filter for which records are updated, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`</td></tr><tr><td>filterParams</td><td>struct</td><td>No</td><td>Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`</td></tr><tr><td>extraFilters</td><td>array</td><td>No</td><td>An array of extra sets of filters. Each array should contain a structure with :code:`filter` and optional `code:`filterParams` keys.</td></tr><tr><td>savedFilters</td><td>array</td><td>No</td><td></td></tr><tr><td>forceUpdateAll</td><td>boolean</td><td>No (default=false)</td><td>If no ID and no filters are supplied, this must be set to **true** in order for the update to process</td></tr><tr><td>updateManyToManyRecords</td><td>boolean</td><td>No (default=false)</td><td>Whether or not to update multiple relationship records for properties that have a many-to-many relationship</td></tr><tr><td>isDraft</td><td>boolean</td><td>No (default=false)</td><td>Whether or not the record update is a draft change. Draft changes are only saved against the version table until published.</td></tr><tr><td>useVersioning</td><td>boolean</td><td>No (default=auto)</td><td>Whether or not to use the versioning system with the update. If the object is setup to use versioning (default), this will default to true.</td></tr><tr><td>versionNumber</td><td>numeric</td><td>No (default=0)</td><td>If using versioning, specify a version number to save against (if none specified, one will be created automatically)</td></tr><tr><td>forceVersionCreation</td><td>boolean</td><td>No (default=false)</td><td></td></tr><tr><td>setDateModified</td><td>boolean</td><td>No (default=true)</td><td>If true (default), updateData will automatically set the datelastmodified date on your record to the current date/time</td></tr></tbody></table></div>


## Examples


```luceescript
// update a single record
updated = presideObjectService.updateData(
          objectName = "event"
        , id         = eventId
        , data       = { enddate = "2015-01-31" }
);


// update multiple records
updated = presideObjectService.updateData(
          objectName     = "event"
        , data           = { cancelled = true }
        , filter         = { category = rc.category }
);


// update all records
updated = presideObjectService.updateData(
          objectName     = "event"
        , data           = { cancelled = true }
        , forceUpdateAll = true
);
```