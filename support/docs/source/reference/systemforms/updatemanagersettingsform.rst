Update manager settings form
============================

*/forms/update-manager/general.settings.xml*

This form is used for updating general settings of the Update manager. i.e. Which release branch should updates be fetch from, etc.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="administrator">
            <fieldset id="administrator">
                <field name="branch"         control="select"   required="true"  label="cms:updateManager.branch.field.label"         values="release,stable,bleedingEdge" labels="cms:updateManager.branch.release,cms:updateManager.branch.stable,cms:updateManager.branch.bleedingEdge" />
                <field name="railo_admin_pw" control="password" required="false" label="cms:updateManager.railo_admin_pw.field.label" placeholder="cms:updateManager.railo_admin_pw.field.placeholder" />
            </fieldset>
        </tab>
    </form>

