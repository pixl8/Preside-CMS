---
id: "form-usereditselfform"
title: "User: edit self form"
---

This form is used for the "edit user" form in the user admin section of the administrator **when the user being edited is the same as the logged in user**.

>>> This form gets mixed in with [[form-usereditform]]. Its purpose is to remove the "active" flag control, preventing the user from deactivating themselves (the service layer also prevents this).

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/security_user/admin.edit.self.xml</td></tr><tr><th>Form ID</th><td>preside-objects.security_user.admin.edit.self</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic">
        <fieldset id="basic">
            <field name="active" deleted="true" />
        </fieldset>
    </tab>
</form>
```