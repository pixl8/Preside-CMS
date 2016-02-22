---
id: "form-websiteuserchangepasswordform"
title: "Website User: change password form"
---

This form is used for the "change password" for website users form in the admin

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/website_user/admin.change.password.xml</td></tr><tr><th>Form ID</th><td>preside-objects.website_user.admin.change.password</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10">
        <fieldset id="basic" sortorder="10">
            <field name="password" control="password" required="false" label="preside-objects.security_user:field.new_password.title" passwordPolicyContext="website" />
            <field name="confirm_password" control="password" required="false" label="preside-objects.security_user:field.confirm_password.title">
                <rule validator="sameAs">
                    <param name="field" value="password" />
                </rule>
            </field>
        </fieldset>
    </tab>
</form>
```