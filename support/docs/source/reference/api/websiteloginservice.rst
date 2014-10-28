Website login service
=====================

Overview
--------

**Full path:** *preside.system.services.websiteUsers.WebsiteLoginService*

The website login manager object provides methods for member login, logout and session retrieval


See also: :doc:`/devguides/websiteusers`

Public API Methods
------------------

.. _websiteloginservice-login:

Login()
~~~~~~~

.. code-block:: java

    public boolean function login( required string loginId, required string password, boolean rememberLogin=false, any rememberExpiryInDays=90 )

Logs the user in by matching the passed login id against either the login id or email address
fields and running a bcrypt password check to verify the security credentials. Returns true on success, false otherwise.

Arguments
.........

====================  =======  ==================  =====================================================================================
Name                  Type     Required            Description                                                                          
====================  =======  ==================  =====================================================================================
loginId               string   Yes                 Either the login id or email address of the user to login                            
password              string   Yes                 The password that the user has entered during login                                  
rememberLogin         boolean  No (default=false)  Whether or not to set a "remember me" cookie                                         
rememberExpiryInDays  any      No (default=90)     When setting a remember me cookie, how long (in days) before the cookie should expire
====================  =======  ==================  =====================================================================================


.. _websiteloginservice-logout:

Logout()
~~~~~~~~

.. code-block:: java

    public void function logout( )

Logs the currently logged in user out of their session

Arguments
.........

*This method does not accept any arguments.*

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


.. _websiteloginservice-isautologgedin:

IsAutoLoggedIn()
~~~~~~~~~~~~~~~~

.. code-block:: java

    public boolean function isAutoLoggedIn( )

Returns whether or not the user making the current request is only automatically logged in.
This would happen when the user has been logged in via a "remember me" cookie. System's can
make use of this method when protecting pages that require a full authenticated session, forcing
a login prompt when this method returns true.

Arguments
.........

*This method does not accept any arguments.*

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

.. _websiteloginservice-sendpasswordresetinstructions:

SendPasswordResetInstructions()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public boolean function sendPasswordResetInstructions( required string loginId )

Sends password reset instructions to the supplied user. Returns true if successful, false otherwise.

Arguments
.........

=======  ======  ========  ================================================
Name     Type    Required  Description                                     
=======  ======  ========  ================================================
loginId  string  Yes       Either the email address or login id of the user
=======  ======  ========  ================================================
