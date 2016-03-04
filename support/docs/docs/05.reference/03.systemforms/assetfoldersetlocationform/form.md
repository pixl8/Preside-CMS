---
id: "form-assetfoldersetlocationform"
title: "Asset folder: set location form"
---

This form is used for setting the storage location for a folder in the asset manager section of the administrator.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/asset_folder/admin.setlocation.xml</td></tr><tr><th>Form ID</th><td>preside-objects.asset_folder.admin.setlocation</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10" title="preside-objects.asset_folder:basic.tab.title">
        <fieldset id="basic" sortorder="10">
            <field sortorder="10" binding="asset_folder.storage_location" control="AssetStorageLocationPicker" />
        </fieldset>
    </tab>
</form>
```