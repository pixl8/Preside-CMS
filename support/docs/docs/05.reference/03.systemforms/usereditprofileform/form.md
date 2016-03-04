---
id: "form-usereditprofileform"
title: "User: edit profile form"
---

This form is used for the "edit my profile" form

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/security_user/admin.edit.profile.xml</td></tr><tr><th>Form ID</th><td>preside-objects.security_user.admin.edit.profile</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10">
        <fieldset id="basic" sortorder="10">
            <field binding="security_user.email_address" required="true" />
            <field binding="security_user.known_as" />
            <field name="password" control="password" required="false" label="preside-objects.security_user:field.new_password.title" passwordPolicyContext="cms" />
            <field name="confirm_password" control="password" required="false" label="preside-objects.security_user:field.confirm_password.title">
                <rule validator="sameAs">
                    <param name="field" value="password" />
                </rule>
            </field>
        </fieldset>
    </tab>
</form>
```