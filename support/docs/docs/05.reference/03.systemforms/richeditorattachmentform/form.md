---
id: "form-richeditorattachmentform"
title: "Richeditor: attachment form"
---

This form is used for the add/edit attachment screen in the richeditor.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/richeditor/attachment.xml</td></tr><tr><th>Form ID</th><td>richeditor.attachment</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="main" sortorder="10">
        <fieldset id="main" sortorder="10">
            <field sortorder="10" name="asset"     control="assetPicker" required="true"  label="cms:ckeditor.attachmentpicker.asset.label" allowedtypes="document" />
            <field sortorder="20" name="link_text" control="textinput"   required="false" label="cms:ckeditor.attachmentpicker.link_text.label" maxLength="200" placeholder="cms:ckeditor.attachmentpicker.link_text.placeholder" />
        </fieldset>
    </tab>
</form>
```