System config
=============

Overview
--------

The system config object is used to store system settings (see :doc:`/devguides/systemsettings`).
See :doc:`/devguides/permissioning` for more information on permissioning.

**Object name:**
    system_config

**Table name:**
    psys_system_config

**Path:**
    /preside-objects/admin/configuration/system_config.cfc

Properties
----------

.. code-block:: java

    property name="category" type="string" dbtype="varchar" maxlength="50" required="true"  uniqueindexes="categorysetting|1";
    property name="setting"  type="string" dbtype="varchar" maxlength="50" required="true"  uniqueindexes="categorysetting|2";
    property name="value"    type="string" dbtype="text"                   required="false";