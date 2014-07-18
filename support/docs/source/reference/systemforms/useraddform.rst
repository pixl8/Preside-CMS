User: add form
==============

*/forms/preside-objects/security_user/admin.add.xml*

This form is used for the "add user" form in the user admin section of the administrator.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab>
            <fieldset title="preside-objects.security_user:fieldset.details" description="preside-objects.security_user:fieldset.details.description">
                <field binding="security_user.email_address" required="true" />
                <field binding="security_user.known_as" />
                <field binding="security_user.login_id" control="autoslug" basedOn="label" />
                <field binding="security_user.groups" />
            </fieldset>

            <fieldset title="preside-objects.security_user:fieldset.security" description="preside-objects.security_user:fieldset.security.description">
                <field binding="security_user.password" control="password" required="false" />
                <field name="confirm_password"      control="password" label="preside-objects.security_user:field.confirm_password.title" required="false">
                    <rule validator="sameAs">
                        <param name="field" value="password" />
                    </rule>
                </field>
            </fieldset>
        </tab>
    </form>

