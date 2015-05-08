System config form: Multilingual settings
=========================================

*/forms/system-config/multilingual.xml*

This form is used for configuring aspects of Preside's multlingual content capabilities

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form feature="multilingual">
        <tab id="default" sortorder="10">
            <fieldset id="default" sortorder="10">
                <field sortorder="10" name="default_language"     control="objectpicker" object="multilingual_language" required="true"  label="system-config.multilingual:default_language.label" help="system-config.multilingual:default_language.help" quickadd="true" quickedit="true" />
                <field sortorder="20" name="additional_languages" control="objectpicker" object="multilingual_language" required="false" label="system-config.multilingual:additional_languages.label" help="system-config.multilingual:additional_languages.help" quickadd="true" quickedit="true" multiple="true" sortable="true" />
            </fieldset>
        </tab>
    </form>

