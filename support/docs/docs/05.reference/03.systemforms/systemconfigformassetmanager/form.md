---
id: "form-systemconfigformassetmanager"
title: "System config form: Asset manager"
---

This form is used for configuring aspects of the asset manager

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/system-config/asset-manager.xml</td></tr><tr><th>Form ID</th><td>system-config.asset-manager</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="default" sortorder="10">
        <fieldset id="default" sortorder="10">
            <field sortorder="10" name="retrieve_metadata" control="yesnoswitch" required="false" label="system-config.asset-manager:retrieve_metadata.label" help="system-config.asset-manager:retrieve_metadata.help" />
        </fieldset>
    </tab>
</form>
```