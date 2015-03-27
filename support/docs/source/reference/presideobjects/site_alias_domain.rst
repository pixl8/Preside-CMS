Site alias domain
=================

Overview
--------

The Site alias domain object represents a single domain that can also be used to serve the site.
Good examples are when you have a separate domain for serving the mobile version of the site,
i.e. www.mysite.com and m.mysite.com.

**Object name:**
    site_alias_domain

**Table name:**
    psys_site_alias_domain

**Path:**
    /preside-objects/core/site_alias_domain.cfc

Properties
----------

.. code-block:: java

    property name="domain" type="string" dbtype="varchar" maxlength="255" required=true uniqueindexes="sitealias|2";
    property name="site" relationship="many-to-one"                       required=true uniqueindexes="sitealias|1";