---
id: "form-passwordpolicyeditform"
title: "Password policy: edit form"
---

This form is used for editing a password policy

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/password_policy/admin.edit.xml</td></tr><tr><th>Form ID</th><td>preside-objects.password_policy.admin.edit</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10" >
        <fieldset id="basic" sortorder="10">
            <field binding="password_policy.min_strength" control="passwordStrengthPicker" />
        </fieldset>
        <fieldset id="detailed">
            <field binding="password_policy.min_length" />
            <field binding="password_policy.min_uppercase" />
            <field binding="password_policy.min_numeric" />
            <field binding="password_policy.min_symbols" />
        </fieldset>
        <fieldset id="messaging">
            <field binding="password_policy.message" />
        </fieldset>
    </tab>
</form>
```