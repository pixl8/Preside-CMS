---
id: "form-systemconfigformemail"
title: "System config form: Email"
---

This form is used for configuring the mail server and other mail related settings

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/system-config/email.xml</td></tr><tr><th>Form ID</th><td>system-config.email</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="default" sortorder="10">
        <fieldset id="default" sortorder="10">
            <field sortorder="10" name="server"               control="textinput" required="false"              label="system-config.email:server.label"               help="system-config.email:server.help" placeholder="system-config.email:server.placeholder" />
            <field sortorder="20" name="port"                 control="spinner"   required="false" default="25" label="system-config.email:port.label"                 help="system-config.email:port.help" maxValue="99999" />
            <field sortorder="30" name="username"             control="textinput" required="false"              label="system-config.email:username.label"             help="system-config.email:username.help" />
            <field sortorder="40" name="password"             control="password"  required="false"              label="system-config.email:password.label"             help="system-config.email:password.help" outputSavedValue="true" />
            <field sortorder="50" name="default_from_address" control="textinput" required="false"              label="system-config.email:default_from_address.label" help="system-config.email:default_from_address.help" placeholder="system-config.email:default_from_address.placeholder" />
        </fieldset>
    </tab>
</form>
```