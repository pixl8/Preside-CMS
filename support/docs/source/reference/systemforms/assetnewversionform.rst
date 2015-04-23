Asset: new version form
=======================

*/forms/preside-objects/asset/newversion.xml*

This form is used when uploading new versions of asset files
through the asset manager interface.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="default" sortorder="10">
            <fieldset id="default" sortorder="10">
                <field name="file" sortorder="10" required="true" control="fileupload" label="cms:assetmanager.newversion.form.file.label" help="cms:assetmanager.newversion.form.file.help" />
            </fieldset>
        </tab>
    </form>

