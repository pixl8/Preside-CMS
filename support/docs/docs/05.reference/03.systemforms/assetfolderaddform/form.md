---
id: "form-assetfolderaddform"
title: "Asset folder: add form"
---

This form is used for adding folders in the asset manager section of the administrator.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/asset_folder/admin.add.xml</td></tr><tr><th>Form ID</th><td>preside-objects.asset_folder.admin.add</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10" title="preside-objects.asset_folder:basic.tab.title">
        <fieldset id="basic" sortorder="10">
            <field sortorder="10" binding="asset_folder.label" />
        </fieldset>
    </tab>
    <tab id="restrictions" sortorder="20" title="preside-objects.asset_folder:restrictions.tab.title">
        <fieldset id="restrictions" sortorder="10">
            <field sortorder="10" binding="asset_folder.allowed_filetypes" control="filetypepicker" multiple="true" />
            <field sortorder="20" binding="asset_folder.max_filesize_in_mb" />
        </fieldset>
    </tab>
    <tab id="permissions" sortorder="30" title="preside-objects.asset_folder:permissions.tab.title" feature="websiteUsers">
        <fieldset id="permissions" sortorder="10">
            <field sortorder="10" binding="asset_folder.access_restriction"                 />
            <field sortorder="15" binding="asset_folder.access_condition" quickadd="true" quickedit="true" feature="rulesengine"/>
            <field sortorder="20" binding="asset_folder.full_login_required"                />
        </fieldset>
        <fieldset id="benefits" sortorder="20" feature="websitebenefits">
            <field sortorder="30" binding="asset_folder.grantaccess_to_all_logged_in_users" />
            <field sortorder="40" name="grant_access_to_benefits" control="objectPicker" object="website_benefit" multiple="true" required="false" label="preside-objects.asset_folder:field.grant_access_to_benefits.title" help="preside-objects.asset_folder:field.grant_access_to_benefits.help" />
            <field sortorder="50" name="deny_access_to_benefits"  control="objectPicker" object="website_benefit" multiple="true" required="false" label="preside-objects.asset_folder:field.deny_access_to_benefits.title"  help="preside-objects.asset_folder:field.deny_access_to_benefits.help"  />
            <field sortorder="60" name="grant_access_to_users"    control="objectPicker" object="website_user"    multiple="true" required="false" label="preside-objects.asset_folder:field.grant_access_to_users.title"    help="preside-objects.asset_folder:field.grant_access_to_users.help"    />
            <field sortorder="70" name="deny_access_to_users"     control="objectPicker" object="website_user"    multiple="true" required="false" label="preside-objects.asset_folder:field.deny_access_to_users.title"     help="preside-objects.asset_folder:field.deny_access_to_users.help"     />
        </fieldset>
    </tab>
</form>
```