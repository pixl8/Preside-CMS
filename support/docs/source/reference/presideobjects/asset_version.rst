Asset
=====

Overview
--------

The asset version object represents the file information for a specific version of a file for a given asset
The active asset version's file details are duplicated in the asset object to reduce API and querying complexity


i.e. to get the file details of the active version of a given asset, one simply has to query the asset itself. This has
also been done to make upgrades easier as this asset version feature has been added later.

**Object name:**
    asset_version

**Table name:**
    psys_asset_version

**Path:**
    /preside-objects/assetManager/asset_version.cfc

Properties
----------

.. code-block:: java

    property name="asset"             relationship="many-to-one" relatedTo="asset"      required=true  uniqueindexes="assetversion|1";
    property name="version_number"    type="numeric" dbtype="int"                       required=true  uniqueindexes="assetversion|2";

    property name="storage_path"      type="string"  dbtype="varchar" maxLength=255     required=true  uniqueindexes="assetversionpath";
    property name="size"              type="numeric" dbtype="int"                       required=true;
    property name="asset_type"        type="string"  dbtype="varchar" maxLength=10      required=true;
    property name="raw_text_content"  type="string"  dbtype="longtext";

    property name="created_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="loggedInUserId";
    property name="updated_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="loggedInUserId";
