---
id: "form-websiteuseraddform"
title: "Website user: add form"
---

This form is used for the "add website user" form in the website user manager

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/website_user/admin.add.xml</td></tr><tr><th>Form ID</th><td>preside-objects.website_user.admin.add</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10" title="preside-objects.website_user:basic.tab.title">
        <fieldset id="basic" sortorder="10">
            <field binding="website_user.login_id"      sortorder="10" control="textinput"  />
            <field binding="website_user.email_address" sortorder="20" control="textinput"  />
            <field binding="website_user.display_name"  sortorder="30" control="textinput"  />
            <field binding="website_user.active"        sortorder="40"  />
        </fieldset>
    </tab>
    <tab id="security" sortorder="20" title="preside-objects.website_user:security.tab.title">
        <fieldset id="security" sortorder="10">
            <field binding="website_user.benefits"      sortorder="10"  />
            <field name="permissions"                   sortorder="20" control="websitePermissionsPicker" label="cms:website.permissions.picker.label" help="cms:website.permissions.picker.help" />
        </fieldset>
    </tab>
</form>
```