Asset
=====

Overview
--------

The asset object represents the core data associated with any file uploaded into the Asset manager

**Object name:**
    asset

**Table name:**
    psys_asset

**Path:**
    /preside-objects/assetManager/asset.cfc

Properties
----------

.. code-block:: java

    property name="asset_folder" relationship="many-to-one"                          required=true   uniqueindexes="assetfolder|1";

    property name="title"             type="string"  dbtype="varchar" maxLength=150     required=true   uniqueindexes="assetfolder|2";
    property name="original_title"    type="string"  dbtype="varchar" maxLength=200     required=false;
    property name="storage_path"      type="string"  dbtype="varchar" maxLength=255     required=true   uniqueindexes="assetpath";
    property name="trashed_path"      type="string"  dbtype="varchar" maxLength=255     required=false;
    property name="description"       type="string"  dbtype="text"    maxLength=0       required=false;
    property name="author"            type="string"  dbtype="varchar" maxLength=100     required=false;
    property name="size"              type="numeric" dbtype="int"                       required=true;
    property name="asset_type"        type="string" dbtype="varchar" maxLength=10       required=true;

    property name="created_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="loggedInUserId";
    property name="updated_by"  relationship="many-to-one" relatedTo="security_user" required=false generator="loggedInUserId";