---
id: formcontrol-radio
title: "Form control: Radio"
---

The `radio` control allows the single choice selection from a pre-defined set of options.

### Arguments

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>values (required)</th>
                <td>Either a comma separated list or array of values for the radio options</td>
            </tr>
            <tr>
                <th>labels (optional)</th>
                <td>Either a comma separated list or array of labels that correspond with the values for each radio button (must be same length as the values list/array). If not supplied, the values will be used for the labels</td>
            </tr>
        </tbody>
    </table>
</div>

### Example

```xml
<field name="number" control="radio" values="1,2,3" labels="One,Two,Three"/>
```
