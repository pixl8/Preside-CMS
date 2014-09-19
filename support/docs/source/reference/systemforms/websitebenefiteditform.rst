Website benefit: edit form
==========================

*/forms/preside-objects/website_benefit/admin.edit.xml*

This form is used for the "edit website benefit" form in the website user manager

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="basic">
            <fieldset id="basic">
                <field binding="website_benefit.label"       sortorder="10"  />
                <field binding="website_benefit.description" sortorder="20"  />
                <field name="permissions"                    sortorder="30" control="websitePermissionsPicker" label="cms:website.permissions.picker.label" help="cms:website.permissions.picker.help" />
            </fieldset>
        </tab>
    </form>

