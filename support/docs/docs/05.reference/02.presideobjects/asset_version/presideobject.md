---
id: "presideobject-asset_version"
title: "Asset version"
---

## Overview


The asset version object represents the file information for a specific version of a file for a given asset
The active asset version's file details are duplicated in the asset object to reduce API and querying complexity


i.e. to get the file details of the active version of a given asset, one simply has to query the asset itself. This has
also been done to make upgrades easier as this asset version feature has been added later.

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  asset_version</td></tr><tr><th>Table name</th><td>  psys_asset_version</td></tr><tr><th>Path</th><td>  /preside-objects/assetManager/asset_version.cfc</td></tr></table></div>

## Properties


```luceescript
property name="asset"             relationship="many-to-one" relatedTo="asset"      required=true  uniqueindexes="assetversion|1" ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
property name="version_number"    type="numeric" dbtype="int"                       required=true  uniqueindexes="assetversion|2";

property name="storage_path"      type="string"  dbtype="varchar" maxLength=255     required=true  uniqueindexes="assetversionpath";
property name="asset_url"         type="string"  dbtype="varchar" maxLength=255     required=false uniqueindexes="assetversionurl";
property name="size"              type="numeric" dbtype="int"                       required=true;
property name="asset_type"        type="string"  dbtype="varchar" maxLength=10      required=true;
property name="raw_text_content"  type="string"  dbtype="longtext";

property name="is_trashed"   type="boolean" dbtype="boolean"               required=false default=false;
property name="trashed_path" type="string"  dbtype="varchar" maxLength=255 required=false;

property name="created_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="loggedInUserId" ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";
property name="updated_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="loggedInUserId" ondelete="cascade-if-no-cycle-check" onupdate="cascade-if-no-cycle-check";

```