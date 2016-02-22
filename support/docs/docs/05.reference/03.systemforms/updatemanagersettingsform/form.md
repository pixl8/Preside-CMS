---
id: "form-updatemanagersettingsform"
title: "Update manager settings form"
---

This form is used for updating general settings of the Update manager. i.e. Which release branch should updates be fetch from, etc.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/update-manager/general.settings.xml</td></tr><tr><th>Form ID</th><td>update-manager.general.settings</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="administrator" sortorder="10">
        <fieldset id="administrator" sortorder="10">
            <field  sortorder="10" name="branch"           control="select"   required="true"  label="cms:updateManager.branch.field.label"         values="release,bleedingEdge" labels="cms:updateManager.branch.release,cms:updateManager.branch.bleedingEdge" />
            <field  sortorder="20" name="railo_admin_pw"   control="password" required="false" label="cms:updateManager.railo_admin_pw.field.label" placeholder="cms:updateManager.railo_admin_pw.field.placeholder" />
            <field  sortorder="30" name="download_timeout" control="spinner"  required="false" label="cms:updateManager.download_timeout.field.label" default="120" />
        </fieldset>
    </tab>
</form>
```