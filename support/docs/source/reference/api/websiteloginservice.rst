Website user service
====================

Overview
--------

**Full path:** *preside.system.services.websiteUsers.WebsiteLoginService*

The website user manager object provides methods for interacting with the front end users of your sites. In particular, it deals with login and user lookups.


See also: :doc:`/reference/presideobjects/website_user`

Public API Methods
------------------

.. _websiteloginservice-isloggedin:

IsLoggedIn()
~~~~~~~~~~~~

.. code-block:: java

    public boolean function isLoggedIn( function securityAlertCallback )

Arguments
.........

=====================  ========  ========  ===========
Name                   Type      Required  Description
=====================  ========  ========  ===========
securityAlertCallback  function  No                   
=====================  ========  ========  ===========


.. _websiteloginservice-getloggedinuserdetails:

GetLoggedInUserDetails()
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public struct function getLoggedInUserDetails( )

Returns the structure of user details belonging to the currently logged in user.
If no user is logged in, an empty structure will be returned.

Arguments
.........

*This method does not accept any arguments.*

.. _websiteloginservice-getloggedinuserid:

GetLoggedInUserId()
~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public string function getLoggedInUserId( )

Returns the id of the currently logged in user, or an empty string if no user is logged in

Arguments
.........

*This method does not accept any arguments.*