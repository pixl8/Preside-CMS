Site service
============

.. contents::
    :depth: 2
    :local:



Overview
--------

**Full path:** *preside.system.services.siteTree.SiteService*

The site service provides methods for interacting with the core "Site" system

Public API Methods
------------------

.. _siteservice-listsites:

ListSites()
~~~~~~~~~~~

.. code-block:: java

    public query function listSites( )

Returns a query of all the registered sites

Arguments
.........

*This method does not accept any arguments.*

.. _siteservice-getsite:

GetSite()
~~~~~~~~~

.. code-block:: java

    public struct function getSite( required string id )

Returns a single site matched by id

Arguments
.........

====  ======  ========  =====================
Name  Type    Required  Description          
====  ======  ========  =====================
id    string  Yes       ID of the site to get
====  ======  ========  =====================


.. _siteservice-matchsite:

MatchSite()
~~~~~~~~~~~

.. code-block:: java

    public struct function matchSite( required string domain, required string path )

Returns the site record that matches the incoming domain and URL path.

Arguments
.........

======  ======  ========  =================================================================
Name    Type    Required  Description                                                      
======  ======  ========  =================================================================
domain  string  Yes       The domain name used in the incoming request, e.g. testsite.com  
path    string  Yes       The URL path of the incoming request, e.g. /path/to/somepage.html
======  ======  ========  =================================================================


.. _siteservice-getactiveadminsite:

GetActiveAdminSite()
~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public struct function getActiveAdminSite( )

Returns the id of the currently active site for the administrator. If no site selected, chooses the first site
that the logged in user has rights to

Arguments
.........

*This method does not accept any arguments.*

.. _siteservice-setactiveadminsite:

SetActiveAdminSite()
~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public void function setActiveAdminSite( required string siteId )

Sets the current active admin site id

Arguments
.........

======  ======  ========  ===========
Name    Type    Required  Description
======  ======  ========  ===========
siteId  string  Yes                  
======  ======  ========  ===========


.. _siteservice-ensuredefaultsiteexists:

EnsureDefaultSiteExists()
~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public void function ensureDefaultSiteExists( )

Ensures that at least one site is registered with the system, called internally
before checking valid routes

Arguments
.........

*This method does not accept any arguments.*

.. _siteservice-getactivesiteid:

GetActiveSiteId()
~~~~~~~~~~~~~~~~~

.. code-block:: java

    public string function getActiveSiteId( )

Retrieves the current active site id. This is based either on the URL, for front-end requests, or the currently
selected site when in the administrator

Arguments
.........

*This method does not accept any arguments.*

.. _siteservice-getactivesitetemplate:

GetActiveSiteTemplate()
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public string function getActiveSiteTemplate( )

Retrieves the current active site template. This is based either on the URL, for front-end requests, or the currently
selected site when in the administrator

Arguments
.........

*This method does not accept any arguments.*

.. _siteservice-syncsitealiasdomains:

SyncSiteAliasDomains()
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public boolean function syncSiteAliasDomains( required string siteId, required string domains )

Sync alias domains with the site record

Arguments
.........

=======  ======  ========  ===========
Name     Type    Required  Description
=======  ======  ========  ===========
siteId   string  Yes                  
domains  string  Yes                  
=======  ======  ========  ===========


.. _siteservice-syncsiteredirectdomains:

SyncSiteRedirectDomains()
~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public boolean function syncSiteRedirectDomains( required string siteId, required string domains )

Sync redirect domains with the site record

Arguments
.........

=======  ======  ========  ===========
Name     Type    Required  Description
=======  ======  ========  ===========
siteId   string  Yes                  
domains  string  Yes                  
=======  ======  ========  ===========
