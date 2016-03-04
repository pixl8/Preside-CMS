---
id: "form-assetnewversionform"
title: "Asset: new version form"
---

This form is used when uploading new versions of asset files
through the asset manager interface.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/asset/newversion.xml</td></tr><tr><th>Form ID</th><td>preside-objects.asset.newversion</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="default" sortorder="10">
        <fieldset id="default" sortorder="10">
            <field name="file" sortorder="10" required="true" control="fileupload" label="cms:assetmanager.newversion.form.file.label" help="cms:assetmanager.newversion.form.file.help" />
        </fieldset>
    </tab>
</form>
```