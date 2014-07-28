Site Templates service
======================

Overview
--------

**Full path:** *preside.system.services.siteTree.SiteTemplatesService*

The site templates service provides methods for discovering and listing out
site templates which are self contained sets of widgets, page types, objects, etc. See :doc:`/devguides/sites`.

Public API Methods
------------------

.. _sitetemplatesservice-listtemplates:

ListTemplates()
~~~~~~~~~~~~~~~

.. code-block:: java

    public array function listTemplates( )

Returns an array of SiteTemplate objects that have been discovered by the system

Arguments
.........

*This method does not accept any arguments.*

.. _sitetemplatesservice-reload:

Reload()
~~~~~~~~

.. code-block:: java

    public void function reload( )

Re-reads all the template directories to repopulate the internal list of templates

Arguments
.........

*This method does not accept any arguments.*