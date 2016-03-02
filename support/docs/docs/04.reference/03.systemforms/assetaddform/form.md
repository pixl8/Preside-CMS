---
id: "form-assetaddform"
title: "Asset: add form"
---

This form is used when adding assets in the asset manager section of the administrator.
For multi file uploads, this form will be rendered once for each file.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/asset/admin.add.xml</td></tr><tr><th>Form ID</th><td>preside-objects.asset.admin.add</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="standard" sortorder="10" title="preside-objects.asset:standard.tab.title">
        <fieldset id="standard" sortorder="10">
            <field sortorder="10" binding="asset.title" />
            <field sortorder="20" binding="asset.author" control="textinput" />
            <field sortorder="30" binding="asset.description" control="textarea" />
        </fieldset>
    </tab>
</form>
```