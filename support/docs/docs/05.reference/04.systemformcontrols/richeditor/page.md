---
id: formcontrol-richeditor
title: "Form control: Rich editor"
---

The `richEditor` control gives the user a PresideCMS rich editor instance that can be used to insert Preside Widgets, images from the asset manager, etc.

For an in-depth guide, see [[workingwiththericheditor]].

### Arguments

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>toolbar (optional)</th>
                <td>An optional toolbar definition for the editor (defaults to "full"). See [[workingwiththericheditor]] for an in-depth guide.</td>
            </tr>
            <tr>
                <th>customConfig (optional)</th>
                <td>An optional custom config location for the editor. See [[workingwiththericheditor]] for an in-depth guide.</td>
            </tr>
            <tr>
                <th>widgetCategories (optional)</th>
                <td>Optional comma separated list of categories of widget that are eligible for insertion into this content. See [[widgets]] for further details.</td>
            </tr>
        </tbody>
    </table>
</div>

### Example

```xml
<field name="body" control="richeditor" />
```

![Screenshot of PresideCMS richeditor](images/screenshots/richeditor.png)


