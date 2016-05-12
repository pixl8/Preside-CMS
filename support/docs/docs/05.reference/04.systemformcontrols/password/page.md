---
id: formcontrol-password
title: "Form control: Password"
---

The `password` control is a variation on the [[formcontrol-textinput|text input control]] that uses `type="password"` on the `<input>` element. It also provides some configurable functionality around providing feedback and validation against password policies 


### Arguments

See arguments that can be passed to the [[formcontrol-textinput|text input control]]. In addition:

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>passwordPolicyContext (optional)</th>
                <td>Either 'admin', or 'website'. If set, a password strength validator and indicator will be provided to match either the website or admin password policy set in the PresideCMS administrator.</td>
            </tr>
            <tr>
                <th>outputSavedValue (optional)</th>
                <td>True of false (default). Whether or not to insecurely output the saved password in the form field when editing a saved record.</td>
            </tr>
        </tbody>
    </table>
</div>

### Example

```xml
<field name="password" control="password" required="true" passwordPolicyContext="website" />
```