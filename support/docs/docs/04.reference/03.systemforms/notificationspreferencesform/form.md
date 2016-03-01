---
id: "form-notificationspreferencesform"
title: "Notifications: preferences form"
---

This form is used for managing a user's notification preferences

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/notifications/preferences.xml</td></tr><tr><th>Form ID</th><td>notifications.preferences</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="basic" sortorder="10" >
        <fieldset id="basic" sortorder="10">
            <field sortorder="10" name="subscriptions" control="notificationTopicPicker" label="cms:notifications.preferences.form.topics.label" help="cms:notifications.preferences.form.topics.help" />
        </fieldset>
    </tab>
</form>
```