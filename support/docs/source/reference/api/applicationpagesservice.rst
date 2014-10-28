ApplicationPagesService
=======================

Overview
--------

**Full path:** *preside.system.services.applicationPages.ApplicationPagesService*

Service for interacting with application pages. See :doc:`/devguides/applicationpages`.

Public API Methods
------------------

.. _applicationpagesservice-listpages:

ListPages()
~~~~~~~~~~~

.. code-block:: java

    public array function listPages( )

Returns an array of ids of all the registered application pages

Arguments
.........

*This method does not accept any arguments.*

.. _applicationpagesservice-getpage:

GetPage()
~~~~~~~~~

.. code-block:: java

    public struct function getPage( required string id )

Returns configured details of the page referred to in the passed 'id' argument

Arguments
.........

====  ======  ========  =================================================
Name  Type    Required  Description                                      
====  ======  ========  =================================================
id    string  Yes       ID of the page who's details you wish to retrieve
====  ======  ========  =================================================


.. _applicationpagesservice-pageexists:

PageExists()
~~~~~~~~~~~~

.. code-block:: java

    public boolean function pageExists( required string id )

Returns whether or not the passed in page is registered with the system

Arguments
.........

====  ======  ========  ====================================
Name  Type    Required  Description                         
====  ======  ========  ====================================
id    string  Yes       ID of the page that we wish to check
====  ======  ========  ====================================


.. _applicationpagesservice-getpageidbyhandler:

GetPageIdByHandler()
~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public string function getPageIdByHandler( required string handler )

Returns the id of the page who's coldbox handler is registered as the passed handler

Arguments
.........

=======  ======  ========  ================================================
Name     Type    Required  Description                                     
=======  ======  ========  ================================================
handler  string  Yes       The ColdBox handler with which to match the page
=======  ======  ========  ================================================


.. _applicationpagesservice-gettree:

GetTree()
~~~~~~~~~

.. code-block:: java

    public array function getTree( )

Returns all the application pages in a tree array. Returns just ids and ids of children.

Arguments
.........

*This method does not accept any arguments.*

.. _applicationpagesservice-getpageconfigformname:

GetPageConfigFormName()
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public string function getPageConfigFormName( required string id )

Returns the name of the form to use for configuring a given application page

Arguments
.........

====  ======  ========  ================================================================
Name  Type    Required  Description                                                     
====  ======  ========  ================================================================
id    string  Yes       ID of the page who's configuration form name we wish to retrieve
====  ======  ========  ================================================================


.. _applicationpagesservice-getpageconfiguration:

GetPageConfiguration()
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public struct function getPageConfiguration( required string id )

Returns the stored page configuration for the given page merged
with any defaults saved in the form definition of the page

Arguments
.........

====  ======  ========  ==========================================
Name  Type    Required  Description                               
====  ======  ========  ==========================================
id    string  Yes       ID of the page who's config we wish to get
====  ======  ========  ==========================================


.. _applicationpagesservice-savepageconfiguration:

SavePageConfiguration()
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public void function savePageConfiguration( required string id, required struct config )

Saves the passed page configuration to the database

Arguments
.........

======  ======  ========  =========================================
Name    Type    Required  Description                              
======  ======  ========  =========================================
id      string  Yes       ID of the page who's config we are saving
config  struct  Yes       Structure of configuration data          
======  ======  ========  =========================================
