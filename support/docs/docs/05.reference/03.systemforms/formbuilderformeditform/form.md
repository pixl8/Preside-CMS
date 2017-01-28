---
id: "form-formbuilderformeditform"
title: "Form builder form: edit form"
---

This form is used for editing form settings within the form builder system.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/formbuilder_form/admin.edit.xml</td></tr><tr><th>Form ID</th><td>preside-objects.formbuilder_form.admin.edit</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form i18nBaseUri="preside-objects.formbuilder_form:">
    <tab id="default">
        <fieldset id="default" sortorder="10">
            <field sortorder="10" binding="formbuilder_form.name"                   control="textinput" />
            <field sortorder="20" binding="formbuilder_form.button_label"           control="textinput" />
            <field sortorder="30" binding="formbuilder_form.use_captcha"                                />
            <field sortorder="40" binding="formbuilder_form.form_submitted_message"                     />
            <field sortorder="50" binding="formbuilder_form.description"            control="textarea"  />
            <field sortorder="60" binding="formbuilder_form.active_from"                                />
            <field sortorder="70" binding="formbuilder_form.active_to"                                  />
        </fieldset>
    </tab>
</form>
```