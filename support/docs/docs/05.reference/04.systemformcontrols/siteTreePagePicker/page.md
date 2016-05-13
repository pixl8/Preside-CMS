---
id: formcontrol-siteTreePagePicker
title: "Form control: Site tree page picker"
---

The `siteTreePagePicker` control allows you to select pages from the site tree. It is a customized extension of the [[formcontrol-objectPicker|object picker control]].

### Arguments

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>multiple (optional)</th>
                <td>True or false (default). Whether or not multiple pages can be selected.</td>
            </tr>
            <tr>
                <th>sortable (optional)</th>
                <td>True or false (default). Whether or not multiple selected pages are sortable within the control's interface.</td>
            </tr>
        </tbody>
    </table>
</div>

### Example

```xml
<field name="pages" control="sitetreePagePicker" multiple="true" sortable="true" />
```