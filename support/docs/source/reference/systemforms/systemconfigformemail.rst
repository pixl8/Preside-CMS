System config form: Email
=========================

*/forms/system-config/email.xml*

This form is used for configuring the mail server and other mail related settings

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="default">
            <fieldset id="default">
                <field name="server"               control="textinput" required="false"              label="system-config.email:server.label"               help="system-config.general:server.help" placeholder="system-config.email:server.placeholder" />
                <field name="port"                 control="spinner"   required="false" default="25" label="system-config.email:port.label"                 help="system-config.general:port.help" maxValue="99999" />
                <field name="default_from_address" control="textinput" required="false"              label="system-config.email:default_from_address.label" help="system-config.general:default_from_address.help" placeholder="system-config.email:default_from_address.placeholder" />
            </fieldset>
        </tab>
    </form>

