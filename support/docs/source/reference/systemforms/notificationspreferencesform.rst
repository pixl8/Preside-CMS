Notifications: preferences form
===============================

*/forms/notifications/preferences.xml*

This form is used for managing a user's notification preferences

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="basic" sortorder="10" >
            <fieldset id="basic" sortorder="10">
                <field sortorder="10" name="subscriptions" control="notificationTopicPicker" label="cms:notifications.preferences.form.topics.label" help="cms:notifications.preferences.form.topics.help" />
            </fieldset>
        </tab>
    </form>

