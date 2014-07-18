Draft
=====

Overview
--------

The draft object represents any draft data that is stored against a specific :doc:`/reference/presideobjects/security_user`.

**Object name:**
    draft

**Table name:**
    psys_draft

**Path:**
    /preside-objects/core/draft.cfc

Properties
----------

.. code-block:: java

    property name="key" type="string"  dbtype="varchar" maxlength="200"        required="true" uniqueindexes="userdraft|1";
    property name="owner" relationship="many-to-one" relatedTo="security_user" required="true" uniqueindexes="userdraft|2" control="none";
    property name="content" type="string" dbtype="longtext" required="false";