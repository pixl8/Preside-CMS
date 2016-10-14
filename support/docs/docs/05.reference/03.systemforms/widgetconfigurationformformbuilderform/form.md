---
id: "form-widgetconfigurationformformbuilderform"
title: "Widget configuration form: Form builder form"
---

This form is used for the configuration of the "Form Builder form" widget. This widget
allows you to drop configured Form Builder forms into your content.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/widgets/formbuilderform.xml</td></tr><tr><th>Form ID</th><td>widgets.formbuilderform</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>


<form i18nBaseUri="widgets.formbuilderform:" categories="formbuilder,system,default">
    <tab>
        <fieldset>
            <field sortorder="10" name="form"       required="true"  control="objectpicker" object="formbuilder_form" objectFilters="activeFormbuilderForms" />
            <field sortorder="20" name="layout"     required="false" control="formBuilderFormLayoutPicker" defaultValue="default" />
            <field sortorder="30" name="instanceid" required="false" control="textinput" />
        </fieldset>
    </tab>
</form>
```