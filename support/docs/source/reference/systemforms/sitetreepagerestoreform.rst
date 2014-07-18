Sitetree Page: restore form
===========================

*/forms/preside-objects/page/restore.xml*

This form is used in the 'restore page' screen in the sitetree section of the administrator.
This occurs when a user wants to restore a page that has been previously deleted and stored in the
recycle bin.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="main">
            <fieldset id="main">
                <field sortorder="10" binding="page.parent_page" control="sitetreePagePicker" required="true" />
                <field sortorder="20" binding="page.slug" />
                <field sortorder="30" binding="page.active" label="cms:sitetree.restore.active.label" />
            </fieldset>
        </tab>
    </form>

