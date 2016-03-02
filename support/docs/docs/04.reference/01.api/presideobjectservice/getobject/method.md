---
id: "presideobjectservice-getobject"
title: "getObject()"
---


## Overview




```luceescript
public any function getObject(
      required string objectName
)
```

Returns an 'auto service' object instance of the given Preside Object.


## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>The name of the object to get</td></tr></tbody></table></div>


## Example
```luceescript
eventObject = presideObjectService.getObject( "event" );
eventId     = eventObject.insertData( data={ title="Christmas", startDate="2014-12-25", endDate="2015-01-06" } );


event       = eventObject.selectData( id=eventId )
```