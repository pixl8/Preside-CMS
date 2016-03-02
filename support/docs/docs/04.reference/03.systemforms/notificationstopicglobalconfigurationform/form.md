---
id: "form-notificationstopicglobalconfigurationform"
title: "Notifications: topic global configuration form"
---

This form is used for managing global notification preferences for a particular topic

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/notifications/topic-global-config.xml</td></tr><tr><th>Form ID</th><td>notifications.topic-global-config</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10" >
        <fieldset id="basic" sortorder="10">
            <field sortorder="10" binding="admin_notification_topic.save_in_cms" />
            <field sortorder="15" binding="admin_notification_topic.available_to_groups" />
            <field sortorder="20" binding="admin_notification_topic.send_to_email_address" control="textinput" />
        </fieldset>
    </tab>
</form>
```