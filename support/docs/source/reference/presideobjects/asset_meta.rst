Asset meta data
===============

Overview
--------

The asset meta object represents a single item of extracted meta data from an asset file

**Object name:**
    asset_meta

**Table name:**
    psys_asset_meta

**Path:**
    /preside-objects/assetManager/asset_meta.cfc

Properties
----------

.. code-block:: java

    property name="asset" relationship="many-to-one"                   required=true   uniqueindexes="assetmeta|1";
    property name="key"   type="string" dbtype="varchar" maxLength=150 required=true   uniqueindexes="assetmeta|2";
    property name="value" type="string" dbtype="text"                  required=false;