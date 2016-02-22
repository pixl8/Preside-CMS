---
id: "presideobjectservice-getrecordversions"
title: "getRecordVersions()"
---


## Overview




```luceescript
public query function getRecordVersions(
      required string objectName
    , required string id        
    ,          string fieldName 
)
```

Returns a summary query of all the versions of a given record (by ID),  optionally filtered by field name

## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>Name of the object who's record we wish to retrieve the version history for</td></tr><tr><td>id</td><td>string</td><td>Yes</td><td>ID of the record who's history we wish to view</td></tr><tr><td>fieldName</td><td>string</td><td>No</td><td>Optional name of one of the object's property which which to filter the history. Doing so will show only versions in which this field changed.</td></tr></tbody></table></div>