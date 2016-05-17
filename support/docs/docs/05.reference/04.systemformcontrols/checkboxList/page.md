---
id: formcontrol-checkboxList
title: "Form control: Checkbox list"
---

The `checkboxList` control allows multiple choice selection of pre-defined set of items.

### Arguments

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>values (required)</th>
                <td>Either a comma separated list or array of values for the checkboxes</td>
            </tr>
            <tr>
                <th>labels (optional)</th>
                <td>Either a comma separated list or array of labels that correspond with the values for each checkbox (must be same length as the values list/array). If not supplied, the values will be used for the labels</td>
            </tr>
        </tbody>
    </table>
</div>

### Example

```xml
<field name="numbers" control="checkboxList" values="1,2,3" labels="One,Two,Three"/>
```