User group
==========

Overview
--------

User groups allow you to bulk assign a set of Roles to a number of users.
See :doc:`/devguides/permissioning` for more information on users and permissioning.

**Object name:**
    security_group

**Table name:**
    psys_security_group

**Path:**
    /preside-objects/admin/security/security_group.cfc

Properties
----------

.. code-block:: java

    property name="label" uniqueindexes="role_name";
    property name="description"  type="string"  dbtype="varchar" maxLength="200"  required="false";
    property name="roles"        type="string"  dbtype="varchar" maxLength="1000" required="false" control="rolepicker" multiple="true";