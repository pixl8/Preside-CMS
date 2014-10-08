Richeditor: attachment form
===========================

*/forms/richeditor/attachment.xml*

This form is used for the add/edit attachment screen in the richeditor.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="main" sortorder="10">
            <fieldset id="main" sortorder="10">
                <field sortorder="10" name="asset"     control="assetPicker" required="true"  label="cms:ckeditor.attachmentpicker.asset.label" allowedtypes="document" />
                <field sortorder="20" name="link_text" control="textinput"   required="false" label="cms:ckeditor.attachmentpicker.link_text.label" maxLength="200" />
            </fieldset>
        </tab>
    </form>

