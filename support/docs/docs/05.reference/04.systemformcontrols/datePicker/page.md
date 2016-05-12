---
id: formcontrol-datePicker
title: "Form control: Date picker"
---

The `datePicker` control allows users to choose a date from a calendar popup.

### Arguments

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>minDate (optional)</th>
                <td>Minimum date allowed to be selected</td>
            </tr>
            <tr>
                <th>maxDate (optional)</th>
                <td>Maximum date allowed to be selected</td>
            </tr>
        </tbody>
    </table>
</div>

>>> [Work is in progress](https://presidecms.atlassian.net/browse/PRESIDECMS-398) to allow relative date restrictions.

### Example

```xml
<field name="start_date" control="datepicker" minDate="2016-01-01" />
```

![Screenshot of a date picker](images/screenshots/datePicker.png)
