---
id: "presideobject-asset_meta"
title: "Asset meta data"
---

## Overview


The asset meta object represents a single item of extracted meta data from an asset file

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  asset_meta</td></tr><tr><th>Table name</th><td>  psys_asset_meta</td></tr><tr><th>Path</th><td>  /preside-objects/assetManager/asset_meta.cfc</td></tr></table></div>

## Properties


```luceescript
property name="asset"         relationship="many-to-one"                   required=true   uniqueindexes="assetmeta|1" ondelete="cascade";
property name="asset_version" relationship="many-to-one"                   required=false  uniqueindexes="assetmeta|2" ondelete="cascade";
property name="key"           type="string" dbtype="varchar" maxLength=150 required=true   uniqueindexes="assetmeta|3";
property name="value"         type="string" dbtype="text"                  required=false;
```