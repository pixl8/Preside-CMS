---
id: "form-formbuilderformaddform"
title: "Form builder form: add form"
---

This form is used for adding forms to the form builder system.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/formbuilder_form/admin.add.xml</td></tr><tr><th>Form ID</th><td>preside-objects.formbuilder_form.admin.add</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form i18nBaseUri="preside-objects.formbuilder_form:">
    <tab id="default">
        <fieldset id="default" sortorder="10">
            <field sortorder="10" binding="formbuilder_form.name"        control="textinput" />
            <field sortorder="20" binding="formbuilder_form.form_submitted_message"          />
            <field sortorder="30" binding="formbuilder_form.description" control="textarea"  />
            <field sortorder="40" binding="formbuilder_form.active_from"                     />
            <field sortorder="50" binding="formbuilder_form.active_to"                       />
        </fieldset>
    </tab>
</form>
```