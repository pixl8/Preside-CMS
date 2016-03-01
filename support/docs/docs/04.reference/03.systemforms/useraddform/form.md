---
id: "form-useraddform"
title: "User: add form"
---

This form is used for the "add user" form in the user admin section of the administrator.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/security_user/admin.add.xml</td></tr><tr><th>Form ID</th><td>preside-objects.security_user.admin.add</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10">
        <fieldset id="basic" sortorder="10" title="preside-objects.security_user:fieldset.details" description="preside-objects.security_user:fieldset.details.description">
            <field binding="security_user.email_address" required="true" />
            <field binding="security_user.known_as" />
            <field binding="security_user.login_id" control="autoslug" basedOn="label" />
            <field binding="security_user.groups" />
        </fieldset>

        <fieldset id="welcome" sortorder="20" title="preside-objects.security_user:fieldset.welcome" description="preside-objects.security_user:fieldset.welcome.description">
            <field name="send_welcome"    control="yesNoSwitch" default="true" label="preside-objects.security_user:field.send_welcome.title" />
            <field name="welcome_message" control="textarea"    label="preside-objects.security_user:field.welcome_message.title" />
        </fieldset>
    </tab>
</form>
```