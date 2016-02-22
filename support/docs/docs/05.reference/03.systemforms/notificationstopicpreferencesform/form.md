---
id: "form-notificationstopicpreferencesform"
title: "Notifications: topic preferences form"
---

This form is used for managing a user's notification preferences for specific topics

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/notifications/topic-preferences.xml</td></tr><tr><th>Form ID</th><td>notifications.topic-preferences</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10" >
        <fieldset id="basic" sortorder="10">
            <field sortorder="10" binding="admin_notification_subscription.get_email_notifications" />
        </fieldset>
    </tab>
</form>
```