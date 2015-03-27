Asset derivative
================

Overview
--------

The asset derivative object represents a derived version of an :doc:`/reference/presideobjects/asset`, storing the file path and named derivative used to transform the initial asset.

**Object name:**
    asset_derivative

**Table name:**
    psys_asset_derivative

**Path:**
    /preside-objects/assetManager/asset_derivative.cfc

Properties
----------

.. code-block:: java

    property name="asset"      relationship="many-to-one" required=true uniqueindexes="derivative|1";

    property name="label" maxLength=200 required=true uniqueindexes="derivative|2"; // unique derivative label per asset

    property name="storage_path" type="string" dbtype="varchar" maxLength=255 required=true   uniqueindexes="assetpath";
    property name="trashed_path" type="string" dbtype="varchar" maxLength=255 required=false;
    property name="asset_type"   type="string" dbtype="varchar" maxLength=10  required=true;