---
id: formcontrol-assetPicker
title: "Form control: Asset picker"
---

The `assetPicker` form control is a customized extension of the [[formcontrol-objectPicker|object picker]] that allows you to:

* search for, and choose assets from the asset manager
* browse and choose assets from the asset manager
* upload and select assets into the asset manager

### Arguments

In addition to the standard arguments for the [[formcontrol-objectPicker|object picker]], the control can take:

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>allowedTypes (optional)</th>
                <td>Comma separated list of asset types that are accepted. e.g. "image", "document", or "png,jpg", etc.</td>
            </tr>
            <tr>
                <th>maxFileSize (optional)</th>
                <td>Maximum size, in MB, for uploaded files</td>
            </tr>
        </tbody>
    </table>
</div> 

### Example

```xml
<field name="images" control="assetPicker" allowedTypes="image" maxFileSize="0.5" multiple="true" sortable="true" />
```

![Screenshot of an asset picker](images/screenshots/assetPicker.png)
