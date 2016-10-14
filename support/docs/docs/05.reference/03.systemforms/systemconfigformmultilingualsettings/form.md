---
id: "form-systemconfigformmultilingualsettings"
title: "System config form: Multilingual settings"
---

This form is used for configuring aspects of Preside's multlingual content capabilities

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/system-config/multilingual.xml</td></tr><tr><th>Form ID</th><td>system-config.multilingual</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form feature="multilingual" i18nBaseUri="system-config.multilingual:">
    <tab id="default" sortorder="10">
        <fieldset id="default" sortorder="10">
            <field sortorder="10" name="default_language"     control="objectpicker" object="multilingual_language" required="true"  quickadd="true" quickedit="true" />
            <field sortorder="20" name="additional_languages" control="objectpicker" object="multilingual_language" required="false" quickadd="true" quickedit="true" multiple="true" sortable="true" />
            <field sortorder="30" name="urls_enabled"         control="yesNoSwitch" />
        </fieldset>
    </tab>
</form>
```