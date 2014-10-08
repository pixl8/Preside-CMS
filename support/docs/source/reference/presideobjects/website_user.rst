Website user
============

Overview
--------

The website user object represents the login details of someone / something that can log into the front end website (as opposed to the admin)

**Object name:**
    website_user

**Table name:**
    psys_website_user

**Path:**
    /preside-objects/websiteUserManagement/website_user.cfc

Properties
----------

.. code-block:: java

    property name="login_id"                    type="string"   dbtype="varchar" maxLength="255" required=true uniqueindexes="login_id";
    property name="email_address"               type="string"   dbtype="varchar" maxLength="255" required=true uniqueindexes="email";
    property name="password"                    type="string"   dbtype="varchar" maxLength="60"  required=false;
    property name="display_name"                type="string"   dbtype="varchar" maxLength="255" required=true;
    property name="active"                      type="boolean"  dbtype="boolean"                 required=false default=true;
    property name="reset_password_token"        type="string"   dbtype="varchar" maxLength="35"  required=false indexes="resettoken";
    property name="reset_password_key"          type="string"   dbtype="varchar" maxLength="60"  required=false;
    property name="reset_password_token_expiry" type="datetime" dbtype="datetime"                required=false;

    property name="benefits" relationship="many-to-many" relatedTo="website_benefit";