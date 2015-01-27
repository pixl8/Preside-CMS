Notifications: topic preferences form
=====================================

*/forms/notifications/topic-preferences.xml*

This form is used for managing a user's notification preferences for specific topics

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="basic" sortorder="10" >
            <fieldset id="basic" sortorder="10">
                <field sortorder="10" binding="admin_notification_subscription.get_email_notifications" />
            </fieldset>
        </tab>
    </form>

