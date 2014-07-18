User: edit form
===============

*/forms/preside-objects/security_user/admin.edit.xml*

This form is used for the "edit user" form in the user admin section of the administrator.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="basic">
            <fieldset id="basic" title="preside-objects.security_user:fieldset.details" description="preside-objects.security_user:fieldset.details.description">
                <field binding="security_user.email_address" required="true" />
                <field binding="security_user.known_as" />
                <field binding="security_user.active" />
                <field binding="security_user.groups" />
            </fieldset>
        </tab>
    </form>

