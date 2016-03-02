---
id: "form-assetstoragelocationaddform"
title: "Asset storage location: add form"
---

This form is used for adding locations to the asset manager. Storage provider
specific forms will be merged with this form for the final result.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/asset_storage_location/admin.add.xml</td></tr><tr><th>Form ID</th><td>preside-objects.asset_storage_location.admin.add</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="default" sortorder="10">
        <fieldset id="default" sortorder="10">
            <field binding="asset_storage_location.name" sortorder="10" control="textinput" />
        </fieldset>
    </tab>
</form>
```