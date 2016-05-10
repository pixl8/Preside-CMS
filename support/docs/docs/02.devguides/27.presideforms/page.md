---
id: presideforms
title: Preside forms system
---

## Introduction

PresideCMS provides a built-in forms system which allows you to define user-input forms that can be used throughout the admin and in your application's front-end. 

>>>> The Preside forms system is not to be confused with the [[formbuilder|PresideCMS Form builder]]. The form builder is a system in which content editors can produce dynamically configured forms and insert them into content pages. The Preside Forms system is a system of programatically defining forms that can be used either in the admin interface or hard wired into the application's front end interfaces.

Forms are defined using xml files that live under a `/forms` directory. A typical form definition file will look like this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="form.my-form:">
    <tab id="basic" sortorder="10">
        <fieldset id="basic" sortorder="10">
            <field binding="my_obj.my_field"      sortorder="10" />
            <field binding="my_obj.another_field" sortorder="20" />
        </fieldset>
    </tab>
    <tab id="advanced" sortorder="20">
        <fieldset id="advanced" sortorder="10">
            <field binding="my_obj.advanced_option" sortorder="10" />
        </fieldset>
    </tab>
</form>
```

An example admin render of a form with multiple tabs and fields might look like this:

![Screenshot showing example of a rendered form in the admin](images/screenshots/formExample.png)


## Further reading

* [[presideforms-anatomy]]
* [[presideforms-controls]]
* [[presideforms-i18n]]
* [[presideforms-rendering]]
* [[presideforms-validation]]
* [[presideforms-processing]]
* [[presideforms-merging]]
* [[presideforms-dynamic]]
* [[presideforms-features]]
* [[systemforms|Reference: System form definitions]]
* [[systemformcontrols|Reference: System form controls]]





