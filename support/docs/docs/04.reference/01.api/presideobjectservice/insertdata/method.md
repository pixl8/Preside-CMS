---
id: "presideobjectservice-insertdata"
title: "insertData()"
---


## Overview




```luceescript
public any function insertData(
      required string  objectName             
    , required struct  data                   
    ,          boolean insertManyToManyRecords = false
    ,          boolean useVersioning           = automatic
    ,          numeric versionNumber           = 0
)
```

Inserts a record into the database, returning the ID of the newly created record


## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>Name of the object in which to to insert a record</td></tr><tr><td>data</td><td>struct</td><td>Yes</td><td>Structure of data who's keys map to the properties that are defined on the object</td></tr><tr><td>insertManyToManyRecords</td><td>boolean</td><td>No (default=false)</td><td>Whether or not to insert multiple relationship records for properties that have a many-to-many relationship</td></tr><tr><td>useVersioning</td><td>boolean</td><td>No (default=automatic)</td><td>Whether or not to use the versioning system with the insert. If the object is setup to use versioning (default), this will default to true.</td></tr><tr><td>versionNumber</td><td>numeric</td><td>No (default=0)</td><td>If using versioning, specify a version number to save against (if none specified, one will be created automatically)</td></tr></tbody></table></div>


Example:


```luceescript
newId = presideObjectService.insertData(
          objectName = "event"
        , data       = { name="Summer BBQ", startdate="2015-08-23", enddate="2015-08-23" }
);
```