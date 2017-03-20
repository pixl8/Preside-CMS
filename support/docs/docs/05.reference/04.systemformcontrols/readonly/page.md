---
id: formcontrol-readonly
title: "Form control: Read only"
---

The `readonly` form control will output any saved data without rendering any form controls. This can be useful for edit forms where you would like to show the content of a field that cannot be edited.

If the object property being rendered is a `date` or `datetime`, the control will automatically use the appropriate core renderer to display the data. Alternatively, you can specify a custom renderer to use.

### Arguments

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>renderer (optional)</th>
                <td>The name of the content renderer to use to format the data on screen.</td>
            </tr>
            <tr>
                <th>rendererContext (optional)</th>
                <td>The renderer context to use to render the data - for example, in admin screens you may wish to use the `admin` context. Default is "readonly" (which will fall back to "default" if the readonly contet is not defined).</td>
            </tr>
        </tbody>
    </table>
</div>

### Example

```xml
<field binding="my_protected_object.title"               control="readonly"   />
<field binding="my_protected_object.date"                control="readonly"   renderer="custom_date_renderer" rendererContext="admin" />
<field binding="my_protected_object.website_description" control="richeditor" />
```
