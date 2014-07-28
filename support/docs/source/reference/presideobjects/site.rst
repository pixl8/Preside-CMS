Site
====

Overview
--------

The Site object represents a site / microsite that is managed by the CMS.
Each site will have its own tree of :doc:`/reference/presideobjects/page` records.

**Object name:**
    site

**Table name:**
    psys_site

**Path:**
    /preside-objects/core/site.cfc

Properties
----------

.. code-block:: java

    property name="name"     type="string" dbtype="varchar" maxlength="200" required=true  uniqueindexes="sitename";
    property name="domain"   type="string" dbtype="varchar" maxlength="255" required=true  uniqueindexes="sitepath|1" format="regex:^[a-zA-Z0-9][a-zA-Z0-9-_\.]+$";
    property name="path"     type="string" dbtype="varchar" maxlength="255" required=true  uniqueindexes="sitepath|2" format="regex:^\/[a-zA-Z0-9\/-_]*$";
    property name="protocol" type="string" dbtype="varchar" maxlength="5"   required=false                            format="regex:^https?$";
    property name="template" type="string" dbtype="varchar" maxlength="50"  required=false;