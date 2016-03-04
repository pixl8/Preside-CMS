---
id: "form-maintenancemodesettingsform"
title: "Maintenance mode: settings form"
---

This form is used for managing maintenance mode settings such as IP whitelist, custom message and bypass password

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/maintenance-mode/settings.xml</td></tr><tr><th>Form ID</th><td>maintenance-mode.settings</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10" >
        <fieldset id="basic" sortorder="10">
            <field name="active"          control="yesnoswitch" label="cms:maintenanceMode.form.active.label"          help="cms:maintenanceMode.form.active.help"  />
            <field name="title"           control="textinput"   label="cms:maintenanceMode.form.title.label"           help="cms:maintenanceMode.form.title.help"           placeholder="cms:maintenanceMode.form.title.placeholder"           />
            <field name="message"         control="richeditor"  label="cms:maintenanceMode.form.message.label"         help="cms:maintenanceMode.form.message.help"         />
            <field name="bypass_password" control="textinput"   label="cms:maintenanceMode.form.bypass_password.label" help="cms:maintenanceMode.form.bypass_password.help" placeholder="cms:maintenanceMode.form.bypass_password.placeholder" />
            <field name="ip_whitelist"    control="textarea"    label="cms:maintenanceMode.form.ip_whitelist.label"    help="cms:maintenanceMode.form.ip_whitelist.help"    />
        </fieldset>
    </tab>
</form>
```