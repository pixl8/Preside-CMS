System config form: General configuration
=========================================

*/forms/system-config/general.xml*

This form is used for the "general" system configuration section.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="administrator">
            <fieldset id="administrator">
                <field name="admin_url" control="textinput" required="false" label="system-config.general:admin_url.label" placeholder="system-config.general:admin_url.placeholder" maxLength="50" />
            </fieldset>
        </tab>
    </form>

