Editable System settings
========================

Overview
########

Editable system settings are settings that effect the working of your entire system and that are editable through the CMS admin GUI.

They are stored against a single data object, :code:`system_config`, and are organised into categories.

.. figure:: /images/system_settings_menu.png

    Screenshot showing system settings with two categories, "General" and "Hipchat integration"
    

Categories
##########

A category groups configuration options into a single form. To define a new category, you must:

1. Create a new form layout file at :code:`/forms/system-config/my-category.xml`. For example:

.. code-block:: xml
    
    <?xml version="1.0" encoding="UTF-8"?>
    <form>
        <tab>
            <fieldset>
                <field name="hipchat_api_key"               control="textinput"   required="true" label="system-config.hipchat-settings:api_key.label" maxLength="50" />
                <field name="hipchat_room_name"             control="textinput"   required="true" label="system-config.hipchat-settings:room_name.label" maxLength="50" /> 
                <field name="hipchat_use_html_notification" control="yesNoSwitch" required="true" label="system-config.hipchat-settings:use_html_notification.label" /> 
            </fieldset>
        </tab>
    </form>


2. Create an i18n resource bundle file at :code:`/i18n/system-config/my-category.properties`. This should at least contain :code:`name` and :code:`description` properties to describe the category. For example:

.. code-block:: properties

    name=Hipchat integration
    description=Configure notifications from PresideCMS into your Hipchat rooms

    api_key.label=API Key
    room_name.label=Room name
    use_html_notification.label=Use HTML notifications


Retrieving settings
###################

From handlers and views
-----------------------

Settings can be retrieved from within your handlers and views with the :code:`getSystemSetting()` method. For example:

.. code-block:: js

    function myHandler( event, rc, prc ) output=false {
        prc.hipchatApiKey = getSystemSetting(
              category = "hipchat-integration"
            , setting  = "hipchat_api_key"
            , default  = "someDefaultApiKey"
        );
    } 

From withing your service layer
-------------------------------

Settings can be injected into your service layer components using the PresideCMS custom WireBox DSL. For example:

.. code-block:: js

    component output=false {
        property name="hipchatApiKey" inject="presidecms:systemsetting:hipchat-integration.hipchat_api_key";

        ...
    }