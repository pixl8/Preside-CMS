Website user service
====================

Overview
--------

**Full path:** *preside.system.services.websiteUsers.WebsiteUserService*

The website user manager object provides methods for interacting with the front end users of your sites. In particular, it deals with login and user lookups.


See also: :doc:`/reference/presideobjects/website_user`

Public API Methods
------------------

.. _websiteuserservice-isloggedin:

IsLoggedIn()
~~~~~~~~~~~~

.. code-block:: java

    public boolean function isLoggedIn( )

Returns whether or not the user making the current request is logged in
to the system.

Arguments
.........

*This method does not accept any arguments.*

.. _websiteuserservice-getloggedinuserdetails:

GetLoggedInUserDetails()
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public struct function getLoggedInUserDetails( )

Returns the structure of user details belonging to the currently logged in user.
If no user is logged in, an empty structure will be returned.

Arguments
.........

*This method does not accept any arguments.*

.. _websiteuserservice-getloggedinuserid:

GetLoggedInUserId()
~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public string function getLoggedInUserId( )

Returns the id of the currently logged in user, or an empty string if no user is logged in

Arguments
.........

*This method does not accept any arguments.*

.. _websiteuserservice-getuserbyloginid:

GetUserByLoginId()
~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public query function getUserByLoginId( required string loginId )

Returns a user record that matches the given login id against either the
login_id field or the email_address field.

Arguments
.........

=======  ======  ========  ==================================================================
Name     Type    Required  Description                                                       
=======  ======  ========  ==================================================================
loginId  string  Yes       The login id / email address with which to query the user database
=======  ======  ========  ==================================================================


.. _websiteuserservice-validatepassword:

ValidatePassword()
~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public boolean function validatePassword( required string plainText, required string hashed )

Returns true if the plain text password matches the given hashed password

Arguments
.........

=========  ======  ========  ===========================================
Name       Type    Required  Description                                
=========  ======  ========  ===========================================
plainText  string  Yes       The password provided by the user          
hashed     string  Yes       The password stored against the user record
=========  ======  ========  ===========================================
