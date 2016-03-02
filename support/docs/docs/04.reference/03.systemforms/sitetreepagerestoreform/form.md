---
id: "form-sitetreepagerestoreform"
title: "Sitetree Page: restore form"
---

This form is used in the 'restore page' screen in the sitetree section of the administrator.
This occurs when a user wants to restore a page that has been previously deleted and stored in the
recycle bin.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/preside-objects/page/restore.xml</td></tr><tr><th>Form ID</th><td>preside-objects.page.restore</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="main" sortorder="10">
        <fieldset id="main" sortorder="10">
            <field sortorder="10" binding="page.parent_page" control="sitetreePagePicker" required="true" />
            <field sortorder="20" binding="page.slug" />
            <field sortorder="30" binding="page.active" label="cms:sitetree.restore.active.label" />
        </fieldset>
    </tab>
</form>
```