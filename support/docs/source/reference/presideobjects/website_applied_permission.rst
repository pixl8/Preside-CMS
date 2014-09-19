Website context permission
==========================

Overview
--------

A website context permission records a grants or deny permission for a given user benefit, permission key and context.

**Object name:**
    website_applied_permission

**Table name:**
    psys_website_applied_permission

**Path:**
    /preside-objects/websiteUserManagement/website_applied_permission.cfc

Properties
----------

.. code-block:: java

    property name="permission_key" type="string"  dbtype="varchar" maxlength="100" required=true  uniqueindexes="context_permission|1";
    property name="granted"        type="boolean" dbtype="boolean"                 required=true;

    property name="context"        type="string"  dbtype="varchar" maxlength="100" required=false uniqueindexes="context_permission|2";
    property name="context_key"    type="string"  dbtype="varchar" maxlength="100" required=false uniqueindexes="context_permission|3";

    property name="benefit" relationship="many-to-one" relatedto="website_benefit" required=false uniqueindexes="context_permission|4" ondelete="cascade";
    property name="user"    relationship="many-to-one" relatedto="website_user"    required=false uniqueindexes="context_permission|5" ondelete="cascade";
