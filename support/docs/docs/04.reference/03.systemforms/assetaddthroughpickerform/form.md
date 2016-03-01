---
id: "form-assetaddthroughpickerform"
title: "Asset: add through picker form"
---

This form is used as the add asset form when a user is uploading assets through the asset picker.
The form will be shown once for each file that has been uploaded.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/asset/picker.add.xml</td></tr><tr><th>Form ID</th><td>preside-objects.asset.picker.add</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="main" sortorder="10">
        <fieldset id="main" sortorder="10">
            <field sortorder="10" binding="asset.title" />
            <field sortorder="20" binding="asset.asset_folder" name="folder" control="assetFolderPicker" />
            <field sortorder="30" binding="asset.author" control="textinput" />
            <field sortorder="40" binding="asset.description" control="textarea" />
        </fieldset>
    </tab>
</form>
```