---
id: "presideobject-asset_storage_location"
title: "Asset storage location"
---

## Overview


An asset storage location represents a location in which assets
are stored. Configuration for the location is stored here
so that the asset manager system can know how to interact with the
given storage provider in order to store and retrieve files in the correct location

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  asset_storage_location</td></tr><tr><th>Table name</th><td>  psys_asset_storage_location</td></tr><tr><th>Path</th><td>  /preside-objects/assetManager/asset_storage_location.cfc</td></tr></table></div>

## Properties


```luceescript
property name="name"            type="string" dbtype="varchar"  maxlength=200 required=true uniqueindexes="name";
property name="storageProvider" type="string" dbtype="varchar"  maxlength=100 required=true renderer="assetStorageProvider";
property name="configuration"   type="string" dbtype="longtext";
```