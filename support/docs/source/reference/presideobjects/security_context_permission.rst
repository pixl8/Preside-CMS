Context permission
==================

Overview
--------

A context permission records a grant or deny permission for a given user user group, permission key and context.
See :doc:`/devguides/permissioning` for more information on permissioning.

**Object name:**
    security_context_permission

**Table name:**
    psys_security_context_permission

**Path:**
    /preside-objects/admin/security/security_context_permission.cfc

Properties
----------

.. code-block:: java

    property name="permission_key" type="string" dbtype="varchar" maxlength="100" required=true uniqueindexes="context_permission|1";
    property name="context"        type="string" dbtype="varchar" maxlength="100" required=true uniqueindexes="context_permission|2";
    property name="context_key"    type="string" dbtype="varchar" maxlength="100" required=true uniqueindexes="context_permission|3";
    property name="security_group" relationship="many-to-one"                     required=true uniqueindexes="context_permission|4";
    property name="granted"        type="boolean" dbtype="boolean" required=true;
