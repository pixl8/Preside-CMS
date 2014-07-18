Asset: add form
===============

*/forms/preside-objects/asset/admin.add.xml*

This form is used when adding assets in the asset manager section of the administrator.
For multi file uploads, this form will be rendered once for each file.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab>
            <fieldset>
                <field binding="asset.title" />
                <field binding="asset.author" control="textinput" />
                <field binding="asset.description" control="textarea" />
            </fieldset>
        </tab>
    </form>

