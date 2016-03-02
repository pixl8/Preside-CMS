---
id: "form-siteeditform"
title: "Site: edit form"
---

This form is used for the "edit site" form in the site manager

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/site/admin.edit.xml</td></tr><tr><th>Form ID</th><td>preside-objects.site.admin.edit</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10" title="preside-objects.site:basic.tab.title">
        <fieldset id="basic" sortorder="10">
            <field binding="site.name"     sortorder="10" control="textinput" />
            <field binding="site.protocol" sortorder="20" control="select"    values="http,https" labels="http://,https://" required="true"   />
            <field binding="site.domain"   sortorder="30" control="textinput" />
            <field binding="site.path"     sortorder="40" control="textinput" />
            <field binding="site.template" sortorder="50" control="sitetemplatepicker"  />
        </fieldset>
    </tab>
    <tab id="seo" sortorder="20" title="preside-objects.site:seo.tab.title">
        <fieldset id="seo" sortorder="10">
            <field binding="site.hide_from_search"     sortorder="10" />
            <field binding="site.author"               sortorder="20" />
            <field binding="site.browser_title_prefix" sortorder="30" />
            <field binding="site.browser_title_suffix" sortorder="40" />
        </fieldset>
    </tab>
    <tab id="advanced" sortorder="30" title="preside-objects.site:advanced.tab.title">
        <fieldset id="advanced" sortorder="10">
            <field name="alias_domains"    sortorder="10" control="textarea" label="preside-objects.site:field.alias_domains.title"    help="preside-objects.site:field.alias_domains.help" />
            <field name="redirect_domains" sortorder="20" control="textarea" label="preside-objects.site:field.redirect_domains.title" help="preside-objects.site:field.redirect_domains.help" />
        </fieldset>
    </tab>
</form>
```