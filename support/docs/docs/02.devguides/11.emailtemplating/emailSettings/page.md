---
id: emailSettings
title: Working with Email centre settings
---

## Email centre settings

The email centre has a general settings form with global email configuration (screenshot below). The form, [[form-emailcentergeneralsettingsform]], is located at `/forms/email/settings/general.xml`. You can provide your own extensions to the form by creating the same file in your application or extension (see [[presideforms]]).

![Screenshot showing email centre general settings](images/screenshots/emailSettingsForm.png)

## Retrieving settings

All settings are saved and retrieved using the `email` category in the [[editablesystemsettings]] system. For example:

```luceescript
// all settings example:
var allEmailSettings = $getPresideCategorySettings( "email" );

// specific setting example:
var defaultFrom = $getPresideSetting( category="email", setting="default_from_address" );
```

