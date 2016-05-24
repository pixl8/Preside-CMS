---
id: formcontrol-autoSlug
title: "Form control: Auto Slug"
---

The `autoSlug` control is a control that will automatically create a "slug" version of the text entered in another field as you type.

### Arguments

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>basedOn (required)</th>
                <td>Field name that this auto slug field should create a slug from, e.g. "title"</td>
            </tr>
            <tr>
                <th>placeholder (optional)</th>
                <td>Placeholder text for the input</td>
            </tr>
        </tbody>
    </table>
</div> 

### Example

```xml
<field name="title" control="textinput"/>
<field name="slug" control="autoSlug" basedOn="title" />
```

![Screenshot of an auto slug control](images/screenshots/autoSlug.png)


