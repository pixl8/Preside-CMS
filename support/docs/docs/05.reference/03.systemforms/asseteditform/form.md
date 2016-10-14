---
id: "form-asseteditform"
title: "Asset: edit form"
---

This form is used when editing assets in the asset manager section of the administrator.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/asset/admin.edit.xml</td></tr><tr><th>Form ID</th><td>preside-objects.asset.admin.edit</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="standard" sortorder="10" title="preside-objects.asset:standard.tab.title">
        <fieldset id="standard" sortorder="10">
            <field sortorder="10" binding="asset.title" />
            <field sortorder="30" binding="asset.author" control="textinput" />
            <field sortorder="40" binding="asset.description" control="textarea" />
        </fieldset>
    </tab>

    <tab id="permissions" sortorder="20" title="preside-objects.asset:permissions.tab.title" feature="websiteUsers">
        <fieldset id="permissions" sortorder="10">
            <field sortorder="10" binding="asset.access_restriction"                 />
            <field sortorder="15" binding="asset.access_condition" quickadd="true" quickedit="true" feature="rulesengine"/>
            <field sortorder="20" binding="asset.full_login_required"                />
        </fieldset>
        <fieldset id="benefits" sortorder="20" feature="websitebenefits">
            <field sortorder="30" binding="asset.grantaccess_to_all_logged_in_users" />
            <field sortorder="40" name="grant_access_to_benefits" control="objectPicker" object="website_benefit" multiple="true" required="false" label="preside-objects.asset:field.grant_access_to_benefits.title" help="preside-objects.asset:field.grant_access_to_benefits.help" />
            <field sortorder="50" name="deny_access_to_benefits"  control="objectPicker" object="website_benefit" multiple="true" required="false" label="preside-objects.asset:field.deny_access_to_benefits.title"  help="preside-objects.asset:field.deny_access_to_benefits.help"  />
            <field sortorder="60" name="grant_access_to_users"    control="objectPicker" object="website_user"    multiple="true" required="false" label="preside-objects.asset:field.grant_access_to_users.title"    help="preside-objects.asset:field.grant_access_to_users.help"    />
            <field sortorder="70" name="deny_access_to_users"     control="objectPicker" object="website_user"    multiple="true" required="false" label="preside-objects.asset:field.deny_access_to_users.title"     help="preside-objects.asset:field.deny_access_to_users.help"     />
        </fieldset>
    </tab>
</form>
```