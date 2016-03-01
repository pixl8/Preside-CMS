---
id: "form-websitebenefiteditform"
title: "Website benefit: edit form"
---

This form is used for the "edit website benefit" form in the website user manager

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/website_benefit/admin.edit.xml</td></tr><tr><th>Form ID</th><td>preside-objects.website_benefit.admin.edit</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10">
        <fieldset id="basic" sortorder="10">
            <field binding="website_benefit.label"                           sortorder="10"  />
            <field binding="website_benefit.description"                     sortorder="20"  />
            <field binding="website_benefit.combined_benefits"               sortorder="30"  />
            <field binding="website_benefit.combined_benefits_are_inclusive" sortorder="40" control="select" values="0,1" labels="preside-objects.website_benefit:exclusive.label,preside-objects.website_benefit:inclusive.label" defaultValue="0" />
            <field name="permissions"                    sortorder="50" control="websitePermissionsPicker" label="cms:website.permissions.picker.label" help="cms:website.permissions.picker.help" />
        </fieldset>
    </tab>
</form>
```