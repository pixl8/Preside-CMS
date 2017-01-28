---
id: "presideobjectservice-getobjectpropertyattribute"
title: "getObjectPropertyAttribute()"
---


## Overview




```luceescript
public string function getObjectPropertyAttribute(
      required string objectName   
    , required string propertyName 
    , required string attributeName
    ,          string defaultValue  = ""
)
```

Returns an arbritary attribute value that is defined on a specified property for an object.


## Arguments


<div class="table-responsive"><table class="table"><thead><tr><th>Name</th><th>Type</th><th>Required</th><th>Description</th></tr></thead><tbody><tr><td>objectName</td><td>string</td><td>Yes</td><td>Name of the object who's property attribute we wish to get</td></tr><tr><td>propertyName</td><td>string</td><td>Yes</td><td>Name of the property who's attribute we wish to get</td></tr><tr><td>attributeName</td><td>string</td><td>Yes</td><td>Name of the attribute who's value we wish to get</td></tr><tr><td>defaultValue</td><td>string</td><td>No (default="")</td><td>Default value for the attribute, should it not exist</td></tr></tbody></table></div>


## Example


```luceescript
maxLength = presideObjectService.getObjectPropertyAttribute(
          objectName    = "event"
        , propertyName  = "name"
        , attributeName = "maxLength"
        , defaultValue  = 200
);
```