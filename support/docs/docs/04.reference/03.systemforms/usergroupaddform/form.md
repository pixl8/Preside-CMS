---
id: "form-usergroupaddform"
title: "User group: add form"
---

This form is used for the "edit user group" form in the user admin section of the administrator.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/security_group/admin.edit.xml</td></tr><tr><th>Form ID</th><td>preside-objects.security_group.admin.edit</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10">
        <fieldset id="basic" sortorder="10">
            <field binding="security_group.label" />
            <field binding="security_group.description" />
            <field binding="security_group.roles"  />
        </fieldset>
    </tab>
</form>
```