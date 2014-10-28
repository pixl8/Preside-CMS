Site redirect domain
====================

Overview
--------

The Site redirect domain object represents a single domain that will permanently redirect to the
default domain for a site.

**Object name:**
    site_redirect_domain

**Table name:**
    psys_site_redirect_domain

**Path:**
    /preside-objects/core/site_redirect_domain.cfc

Properties
----------

.. code-block:: java

    property name="domain" type="string" dbtype="varchar" maxlength="255" required=true uniqueindexes="sitedomain|2";
    property name="site" relationship="many-to-one"                       required=true uniqueindexes="sitedomain|1";