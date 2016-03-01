---
id: "presideobjectservice-getdenormalizedmanytomanydata"
title: "getDeNormalizedManyToManyData()"
---


## Overview




```luceescript
public struct function getDeNormalizedManyToManyData(
      required string  objectName      
    , required string  id              
    ,          boolean fromVersionTable = false
    ,          string  maxVersion       = "HEAD"
    ,          numeric specificVersion  = 0
    ,          array   selectFields    
)
```

Returns a structure of many to many data for a given record. Each structure key represents a many-to-many type property on the object. The value for each key will be a comma separated list of IDs of the related data.


## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>Name of the object who's related data we wish to retrieve</td></tr><tr><td>id</td><td>string</td><td>Yes</td><td>ID of the record who's related data we wish to retrieve</td></tr><tr><td>fromVersionTable</td><td>boolean</td><td>No (default=false)</td><td>Whether or not to retrieve the data from the version history table for the object</td></tr><tr><td>maxVersion</td><td>string</td><td>No (default="HEAD")</td><td>If retrieving from the version history, set a max version number</td></tr><tr><td>specificVersion</td><td>numeric</td><td>No (default=0)</td><td>If retrieving from the version history, set a specific version number to retrieve</td></tr><tr><td>selectFields</td><td>array</td><td>No</td><td></td></tr></tbody></table></div>


## Example


```luceescript
relatedData = presideObjectService.getDeNormalizedManyToManyData(
        objectName = "event"
      , id         = rc.id
);


// the relatedData struct above might look like { tags = "C3635F77-D569-4D31-A794CA9324BC3E70,3AA27F08-819F-4C78-A8C5A97C897DFDE6" }
```