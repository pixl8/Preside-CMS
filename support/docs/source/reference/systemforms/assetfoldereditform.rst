Asset folder: edit form
=======================

*/forms/preside-objects/asset_folder/admin.edit.xml*

This form is used for editing folders in the asset manager section of the administrator.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="basic" title="preside-objects.asset_folder:basic.tab.title">
            <fieldset id="basic">
                <field sortorder="10" binding="asset_folder.parent_folder" control="AssetFolderPicker" />
                <field sortorder="20" binding="asset_folder.label" />
            </fieldset>
        </tab>
        <tab id="restrictions" title="preside-objects.asset_folder:restrictions.tab.title">
            <fieldset id="restrictions">
                <field sortorder="10" binding="asset_folder.allowed_filetypes" control="filetypepicker" multiple="true" />
                <field sortorder="20" binding="asset_folder.max_filesize_in_kb" />
            </fieldset>
        </tab>
    </form>

