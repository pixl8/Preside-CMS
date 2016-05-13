---
id: formcontrol-spinner
title: "Form control: Spinner"
---

The `spinner` control is a control used for numeric input. It provides a text area with up and down arrows for conveniently being able to adjust the numeric input.

### Arguments

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>minValue (optional)</th>
                <td>A minimum value accepted by the control (will trigger validation errors if attempting to submit lower values)</td>
            </tr>
            <tr>
                <th>maxValue (optional)</th>
                <td>A maximum value accepted by the control (will trigger validation errors if attempting to submit higher values)</td>
            </tr>
            <tr>
                <th>step (optional)</th>
                <td>Numeric value defining by how much the value should increase or decrease when the spinner control's up and down buttons are triggered. Default is 1.</td>
            </tr>
        </tbody>
    </table>
</div>

### Example

```xml
<field name="companySize" control="spinner" minvalue="0" maxvalue="200000" step="5000" />
```

