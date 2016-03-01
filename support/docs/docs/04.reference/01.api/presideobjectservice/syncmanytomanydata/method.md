---
id: "presideobjectservice-syncmanytomanydata"
title: "syncManyToManyData()"
---


## Overview




```luceescript
public boolean function syncManyToManyData(
      required string sourceObject  
    , required string sourceProperty
    , required string sourceId      
    , required string targetIdList  
)
```

Synchronizes a record's related object data for a given property. Returns true on success, false otherwise.


## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>sourceObject</td><td>string</td><td>Yes</td><td>The object that contains the many-to-many property</td></tr><tr><td>sourceProperty</td><td>string</td><td>Yes</td><td>The name of the property that is defined as a many-to-many relationship</td></tr><tr><td>sourceId</td><td>string</td><td>Yes</td><td>ID of the record who's related data we are to synchronize</td></tr><tr><td>targetIdList</td><td>string</td><td>Yes</td><td>Comma separated list of IDs of records representing records in the related object</td></tr></tbody></table></div>


## Example


```luceescript
presideObjectService.syncManyToManyData(
          sourceObject   = "event"
        , sourceProperty = "tags"
        , sourceId       = rc.eventId
        , targetIdList   = rc.tags // e.g. "635,1,52,24"
);
```