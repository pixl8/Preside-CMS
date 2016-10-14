---
id: "form-systemconfigformassetmanager"
title: "System config form: Asset manager"
---

This form is used for configuring aspects of the asset manager

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/system-config/asset-manager.xml</td></tr><tr><th>Form ID</th><td>system-config.asset-manager</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form i18nBaseUri="system-config.asset-manager:">
    <tab id="uploads" sortorder="10">
        <fieldset id="uploads" sortorder="10">
            <field sortorder="10" name="max_parallel_uploads" control="spinner" required="false" defaultvalue="5" />
            <field sortorder="20" name="retrieve_metadata" control="yesnoswitch" required="false" />
        </fieldset>
    </tab>
    <tab id="imagemagick" sortorder="10">
        <fieldset id="imagemagick" sortorder="10">
            <field sortorder="10" name="use_imagemagick"         control="yesnoswitch" required="false" />
            <field sortorder="20" name="imagemagick_path"        control="textinput"   required="false" />
            <field sortorder="30" name="imagemagick_timeout"     control="spinner"     required="false" defaultvalue="10" />
            <field sortorder="40" name="imagemagick_interlace"   control="yesnoswitch" required="false" />
            <field sortorder="50" name="imagemagick_concurrency" control="spinner"     required="false" defaultvalue="5" />
        </fieldset>
    </tab>
</form>
```