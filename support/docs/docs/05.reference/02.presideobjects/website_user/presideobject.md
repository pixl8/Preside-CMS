---
id: "presideobject-website_user"
title: "Website user"
---

## Overview


The website user object represents the login details of someone / something that can log into the front end website (as opposed to the admin)

<div class="table-responsive"><table class="table table-condensed"><tr><th>Object name</th><td>  website_user</td></tr><tr><th>Table name</th><td>  psys_website_user</td></tr><tr><th>Path</th><td>  /preside-objects/websiteUserManagement/website_user.cfc</td></tr></table></div>

## Properties


```luceescript
property name="login_id"                    type="string"   dbtype="varchar" maxLength="255" required=true uniqueindexes="login_id";
property name="email_address"               type="string"   dbtype="varchar" maxLength="255" required=true uniqueindexes="email";
property name="password"                    type="string"   dbtype="varchar" maxLength="60"  required=false;
property name="display_name"                type="string"   dbtype="varchar" maxLength="255" required=true;
property name="active"                      type="boolean"  dbtype="boolean"                 required=false default=true;
property name="reset_password_token"        type="string"   dbtype="varchar" maxLength="35"  required=false indexes="resettoken";
property name="reset_password_key"          type="string"   dbtype="varchar" maxLength="60"  required=false;
property name="reset_password_token_expiry" type="datetime" dbtype="datetime"                required=false;
property name="last_logged_in"              type="datetime" dbtype="datetime"                required=false ignoreChangesForVersioning=true;
property name="last_logged_out"             type="datetime" dbtype="datetime"                required=false ignoreChangesForVersioning=true;
property name="last_request_made"           type="datetime" dbtype="datetime"                required=false ignoreChangesForVersioning=true;

property name="benefits" relationship="many-to-many" relatedTo="website_benefit";
```