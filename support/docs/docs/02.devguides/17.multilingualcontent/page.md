---
id: multilingualcontent
title: Multilingual content
---

## Overview

PresideCMS comes packaged with a powerful multilingual content feature that allows you to make your client's pages and other data objects translatable to multiple languages.

Enabling multilingual translations is a case of:

1. Enabling the feature in your `Config.cfc` file
2. Marking the preside objects that you wish to be multilingual with a `multilingual` flag
3. Marking the specific properties of preside objects that you wish to be multilingual with a `multilingual` flag
4. Optionally providing specific form layouts for translations
5. Providing a mechanism in the front-end application for users to choose from configured languages

Once the multilingual content feature is enabled, PresideCMS will provide a basic UI for allowing CMS administrators to translate content and to configure what languages are available. When selecting data for display in your application, PresideCMS will automatically select translations of your multilingual properties for you when available for the currently selected language. If no translation is available, the system will fall back to the default content.

![Screenshot showing selection of configured languages](images/screenshots/select_translations.png)

## Enabling multilingual content

### Global config

Enabling the feature in your applications's `Config.cfc` file is achieved as follows:

```luceescript
public void function configure() {
    super.configure();

    // ...

    settings.features.multilingual.enabled = true;
```


### Configuring specific data objects

Configuring individual [[presidedataobject|Preside Objects]] is done using a `multilingual=true` flag on both the component itself and any properties you wish to be translatable:

```luceescript
/**
 * @multilingual true
 *
 */
component {
    property name="title" multilingual=true // ... (multilingual)
    property name="active" // ... (not multilingual)
}
```

## Configuring languages

Configuring languages is done entirely through the admin user interface and can be performed by your clients if necessary. To navigate to the settings page, go to *System* -> *Settings* -> *Content translations*:

![Screenshot showing configuration of content translation languages in the admin user interface](images/screenshots/translation_settings.png)

## Customizing translation forms

By default, the forms for translating records will be automatically generated. They will contain no tabs or fieldsets and the order of fields may be unpredictable.

To provide a better experience when dealing with records with many fields, you can define an alternative translation form at: 

```
/forms/preside-objects/_translation_objectname/admin.edit.xml // where 'objectname' is the name of your object
```

When dealing with page types and pages, this will be:

```
/forms/preside-objects/_translation_page/admin.edit.xml // for the core page object
/forms/preside-objects/_translation_pagetypename/admin.edit.xml // where 'pagetypename' is the name of your page type
```

## Setting the current language

It is up to your application to choose the way in which it will set the language for the current request. One common way in which to do this would be to allow the user to pick from the available languages and to persist their preference. 

The list of available languages can be obtained with the `listLanguages()` method of the `multilingualPresideObjectService` object, e.g.:

```luceescript
component {
    property name="multilingualPresideObjectService" inject="multilingualPresideObjectService";

    function someHandlerAction( event, rc, prc ) {
        prc.availableLanguages = multilingualPresideObjectService.listLanguages()
    }
}
```

Setting the current language can be done with `event.setLanguage( idOfLanguage )`. An ideal place to do this would be at the beggining of the request. This can be achieved in the `/handlers/General.cfc` handler. For example:

```luceescript
component extends="preside.system.handlers.General" {
    
    // here, userPreferenceService would be some custom service
    // object that was written to get and set user preferences
    // it is for illustration purposes only and not a core service
    property name="userPreferencesService" inject="userPreferencesService";

    function requestStart( event, rc, prc ) {
        super.requestStart( argumentCollection=arguments );

        event.setLanguage( userPreferencesService.getLanguage() );
    }
}
```

>>>>> Notice how the `General.cfc` handler extends `preside.system.handlers.General` and calls `super.requestStart( argumentCollection=arguments )`. Without this logic, the core request start logic would not take place, and the system would likely break completely.
