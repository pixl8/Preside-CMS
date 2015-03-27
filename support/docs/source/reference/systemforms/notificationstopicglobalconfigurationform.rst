Notifications: topic global configuration form
==============================================

*/forms/notifications/topic-global-config.xml*

This form is used for managing global notification preferences for a particular topic

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="basic" sortorder="10" >
            <fieldset id="basic" sortorder="10">
                <field sortorder="10" binding="admin_notification_topic.save_in_cms" />
                <field sortorder="20" binding="admin_notification_topic.send_to_email_address" control="textinput" />
            </fieldset>
        </tab>
    </form>

