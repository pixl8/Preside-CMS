Site service
============

Overview
--------

**Full path:** *preside.system.services.siteTree.SiteService*

The site service provides methods for interacting with the core "Site" system

Public API Methods
------------------

.. _siteservice-matchsite:

MatchSite()
~~~~~~~~~~~

.. code-block:: java

    public string function matchSite( required string domain, required string path )

Returns the ID of the site that matches the incoming domain and URL path.

Arguments
.........

======  ======  ========  =================================================================
Name    Type    Required  Description                                                      
======  ======  ========  =================================================================
domain  string  Yes       The domain name used in the incoming request, e.g. testsite.com  
path    string  Yes       The URL path of the incoming request, e.g. /path/to/somepage.html
======  ======  ========  =================================================================
