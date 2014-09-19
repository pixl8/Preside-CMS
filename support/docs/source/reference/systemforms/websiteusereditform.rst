Website user: edit form
=======================

*/forms/preside-objects/website_user/admin.edit.xml*

This form is used for the "edit website user" form in the website user manager

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="basic" title="preside-objects.website_user:basic.tab.title">
            <fieldset id="basic">
                <field binding="website_user.login_id"      sortorder="10" control="textinput"  />
                <field binding="website_user.email_address" sortorder="20" control="textinput"  />
                <field binding="website_user.display_name"  sortorder="30" control="textinput"  />
                <field binding="website_user.active"        sortorder="40"  />
            </fieldset>
        </tab>
        <tab id="security" title="preside-objects.website_user:security.tab.title">
            <fieldset id="security">
                <field binding="website_user.benefits"      sortorder="10"  />
                <field name="permissions"                   sortorder="20" control="websitePermissionsPicker" label="cms:website.permissions.picker.label" help="cms:website.permissions.picker.help" />
            </fieldset>
        </tab>
    </form>

