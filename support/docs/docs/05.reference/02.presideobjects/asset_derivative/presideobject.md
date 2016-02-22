---
id: "presideobject-asset_derivative"
title: "Asset derivative"
---

## Overview


The asset derivative object represents a derived version of an [[presideobject-asset]], storing the file path and named derivative used to transform the initial asset.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  asset_derivative</td></tr><tr><th>Table name</th><td>  psys_asset_derivative</td></tr><tr><th>Path</th><td>  /preside-objects/assetManager/asset_derivative.cfc</td></tr></table></div>

## Properties


```luceescript
property name="asset"         relationship="many-to-one" required=true  uniqueindexes="derivative|1" ondelete="cascade";
property name="asset_version" relationship="many-to-one" required=false uniqueindexes="derivative|2" ondelete="cascade";

property name="label" maxLength=200 required=true uniqueindexes="derivative|3";

property name="storage_path" type="string" dbtype="varchar" maxLength=255 required=true   uniqueindexes="assetpath";
property name="asset_type"   type="string" dbtype="varchar" maxLength=10  required=true;

property name="is_trashed"   type="boolean" dbtype="boolean"               required=false default=false;
property name="trashed_path" type="string"  dbtype="varchar" maxLength=255 required=false;
```