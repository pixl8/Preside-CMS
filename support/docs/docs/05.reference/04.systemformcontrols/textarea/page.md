---
id: formcontrol-textarea
title: "Form control: Text area"
---

The `textarea` control presents the user with a standard HTML text area.

### Arguments

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>placeholder (optional)</th>
                <td>Placeholder text to appear in the textarea when there is no content. Can be an i18n resource URI</td>
            </tr>
            <tr>
                <th>maxLength (optional)</th>
                <td>Character count limit. If set, the control will show a character counter that changes as you type.</td>
            </tr>
        </tbody>
    </table>
</div>

### Example

```xml
<field name="description" control="textarea" placeholder="e.g. Lorem ipsum" maxlength="200" />
```