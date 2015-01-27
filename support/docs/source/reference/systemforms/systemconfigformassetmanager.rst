System config form: Asset manager
=================================

*/forms/system-config/asset-manager.xml*

This form is used for configuring aspects of the asset manager

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="default" sortorder="10">
            <fieldset id="default" sortorder="10">
                <field sortorder="10" name="retrieve_metadata" control="yesnoswitch" required="false" label="system-config.asset-manager:retrieve_metadata.label" help="system-config.asset-manager:retrieve_metadata.help" />
            </fieldset>
        </tab>
    </form>

