User
====

Overview
--------

A user represents someone who can login to the website administrator.
See :doc:`/devguides/permissioning` for more information on users and permissioning.

**Object name:**
    security_user

**Table name:**
    psys_security_user

**Path:**
    /preside-objects/admin/security/security_user.cfc

Properties
----------

.. code-block:: java

    property name="known_as"                        type="string"   dbtype="varchar" maxLength="50"  required="true";
    property name="login_id"                        type="string"   dbtype="varchar" maxLength="50"  required="true" uniqueindexes="login_id";
    property name="password"                        type="string"   dbtype="varchar" maxLength="60"  required="false";
    property name="email_address"                   type="string"   dbtype="varchar" maxLength="255" required="false" uniqueindexes="email" control="textinput";
    property name="active"                          type="boolean"  dbtype="boolean" required=false default=true;
    property name="reset_password_token"            type="string"   dbtype="varchar" maxLength="35"  required=false indexes="resettoken";
    property name="reset_password_key"              type="string"   dbtype="varchar" maxLength="60"  required=false;
    property name="reset_password_token_expiry"     type="datetime" dbtype="datetime"                required=false;
    property name="subscribed_to_all_notifications" type="boolean"  dbtype="boolean"                 required=false default=true;

    property name="groups" relationship="many-to-many" relatedTo="security_group";