---
id: "presideobjectservice-selectdata"
title: "selectData()"
---


## Overview




```luceescript
public query function selectData(
      required string  objectName        
    ,          string  id                
    ,          array   selectFields       = []
    ,          any     filter             = {}
    ,          struct  filterParams       = {}
    ,          array   extraFilters       = []
    ,          array   savedFilters      
    ,          string  orderBy            = ""
    ,          string  groupBy            = ""
    ,          numeric maxRows            = 0
    ,          numeric startRow           = 1
    ,          boolean useCache           = true
    ,          boolean fromVersionTable   = false
    ,          numeric specificVersion    = 0
    ,          boolean allowDraftVersions
    ,          string  forceJoins         = ""
)
```

Selects database records for the given object based on a variety of input parameters


## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>Name of the object from which to select data</td></tr><tr><td>id</td><td>string</td><td>No</td><td>ID of a record to select</td></tr><tr><td>selectFields</td><td>array</td><td>No (default=[])</td><td>Array of field names to select. Can include relationships, e.g. ['tags.label as tag']</td></tr><tr><td>filter</td><td>any</td><td>No (default={})</td><td>Filter the records returned, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`</td></tr><tr><td>filterParams</td><td>struct</td><td>No (default={})</td><td>Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`</td></tr><tr><td>extraFilters</td><td>array</td><td>No (default=[])</td><td>An array of extra sets of filters. Each array should contain a structure with :code:`filter` and optional `code:`filterParams` keys.</td></tr><tr><td>savedFilters</td><td>array</td><td>No</td><td></td></tr><tr><td>orderBy</td><td>string</td><td>No (default="")</td><td>Plain SQL order by string</td></tr><tr><td>groupBy</td><td>string</td><td>No (default="")</td><td>Plain SQL group by string</td></tr><tr><td>maxRows</td><td>numeric</td><td>No (default=0)</td><td>Maximum number of rows to select</td></tr><tr><td>startRow</td><td>numeric</td><td>No (default=1)</td><td>Offset the recordset when using maxRows</td></tr><tr><td>useCache</td><td>boolean</td><td>No (default=true)</td><td>Whether or not to automatically cache the result internally</td></tr><tr><td>fromVersionTable</td><td>boolean</td><td>No (default=false)</td><td>Whether or not to select the data from the version history table for the object</td></tr><tr><td>specificVersion</td><td>numeric</td><td>No (default=0)</td><td>Can be used to select a specific version when selecting from the version table</td></tr><tr><td>allowDraftVersions</td><td>boolean</td><td>No</td><td>Choose whether or not to allow selecting from draft records and/or versions</td></tr><tr><td>forceJoins</td><td>string</td><td>No (default="")</td><td>Can be set to "inner" / "left" to force *all* joins in the query to a particular join type</td></tr></tbody></table></div>


## Examples


```luceescript
// select a record by ID
event = presideObjectService.selectData( objectName="event", id=rc.id );


// select records using a simple filter.
// notice the 'category.label as categoryName' field - this will
// be automatically selected from the related 'category' object
events = presideObjectService.selectData(
          objectName   = "event"
        , filter       = { category = rc.category }
        , selectFields = [ "event.name", "category.label as categoryName", "event.category" ]
        , orderby      = "event.name"
);


// select records with a plain SQL filter with added SQL params
events = presideObjectService.selectData(
          objectName   = "event"
        , filter       = "category.label like :category.label"
        , filterParams = { "category.label" = "%#rc.search#%" }
);
```