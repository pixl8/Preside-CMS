Application page config
=======================

Overview
--------

The Application Page Config object stores configuration key value pairs for application pages.


See :doc:`/devguides/applicationpages`

**Object name:**
    application_page_config

**Table name:**
    psys_application_page_config

**Path:**
    /preside-objects/core/application_page_config.cfc

Properties
----------

.. code-block:: java

    property name="page_id"      type="string" dbtype="varchar" maxlength="200" required="true"  uniqueindexes="pagesetting|1";
    property name="setting_name" type="string" dbtype="varchar" maxlength="50"  required="true"  uniqueindexes="pagesetting|2";
    property name="value"        type="string" dbtype="text"                    required="false";