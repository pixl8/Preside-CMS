---
id: widgets
title: Widgets
---

One of Preside's most powerful and easy to build features is its widget framework. Technially, a widget is a [[viewlets|Preside viewlet]] for which the editorial user supplies the configuration arguments through a [[presideforms|Preside config form]]. Editorial users are able to insert a Preside widget in any part of a [[workingwiththericheditor||Preside Richeditor field]] and the widget will be fully rendered at runtime. Visually, they look like this:

![Screenshot showing widget selector](images/screenshots/widgetSelection.jpg)

![Screenshot showing widget configurator](images/screenshots/widgetConfiguration.jpg)

![Screenshot showing widget placeholders](images/screenshots/widgetPlaceholders.jpg)


## Creating a new widget

A widget consists of three parts, a viewlet (with optional handler), a configuration form and a `.properties` resource file. Each part is registered through convention of `/widgets.{widgetname}`. So, to create a widget with an ID of 'tableOfContents', you could create the following files

```
/forms/widgets/tableOfContents.xml
/i18n/widgets/tableOfContents.properties
/handlers/widgets/TableOfContents.cfc          // optional, if only view is used
/views/widgets/tableOfContents/index.cfm       // optional, if handler is used
/views/widgets/tableOfContents/placeholder.cfm // optional
```

>>> The `new widget` dev console command gives an easy to use wizard to scaffold these files for you.

### The form

The form is simply any valid Preside form definition (see: [[presideforms]]). With that said, we advise setting a `i18nBaseUri` value to map to the `.properties` file of the widget; this will make supplying labels, icons and placeholders easy to do all in the same widget resource bundle file, e.g.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="widgets.tableOfContents:">
    <tab id="default">
        <fieldset id="default" sortorder="10">
            <field name="title" control="textinput" required="true" />
            <field name="pages" control="siteTreePagePicker" multiple="true" sortable="true" />
        </fieldset>
    </tab>
</form>
```

In addition, and as of Preside 10.7.0, you can also specify a `categories` attribute on your widget `form` element. This will allow you to later filter available widgets for a particular Richeditor instance (see below), e.g.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="widgets.newsletterPromoBox" categories="newsletter,email">
    <tab id="default">
        <fieldset id="default" sortorder="10">
            ...
```

### The i18n resource file

At a minimum, you should supply three keys, `title`, `description` and `iconClass`:

```properties
title=Form Builder Form
description=Embed a Form Builder Form in your content
iconclass=fa-check-square-o
```

These keys will be used in the widget selector to help your content editors choose which widget to insert into their content.

Additional keys can then be used for any purpose you like, for example, configuration field labels, help and placeholders:

```properties
title=Form Builder Form
description=Embed a Form Builder Form in your content
iconclass=fa-check-square-o

# ...

placeholder=Form: {1}

# ...

field.instanceid.title=Instance name
field.instanceid.placeholder=e.g. 'Contact page'
field.instanceid.help=If you plan on embeddeding the same form in multiple locations, you can use the instance name field to report against which instance of the form your visitors used when submitting their responses.

# ...
```

### The render viewlet

The viewlet used to render a widget at runtime will be `widgets.{widgetid}`, or `widgets.{widgetid}.index`. If you're creating a handler, create it at `/handlers/widgets/MyWidget.cfc` and implement an `index` action to process the render.

The `args` struct passed to the action will contain the user configured values from the config form. For example:

```luceescript
// /handlers/widgets/FormBuilderForm.cfc
component {
    property name="formbuilderService" inject="formbuilderService";

    private function index( event, rc, prc, args={} ) {
        var formId   = args.form   ?: "";
        var layout   = args.layout ?: "";
        var rendered = "";

        if ( Len( Trim( formId ) ) ) {
            if ( !formbuilderService.isFormActive( formId ) ) {
                if ( !event.isAdminUser() ) {
                    return "";
                }

                rendered = '<div class="alert alert-warning"><p><strong>' & translateResource( "formbuilder:inactive.form.admin.preview.warning") & '</strong></p></div>';
            }
            rendered &= formbuilderService.renderForm(
                  formId           = formId
                , layout           = layout
                , configuration    = args
                , validationResult = rc.validationResult ?: ""
            );
        }

        return rendered;
    }

    ...
}
```

### Placeholder viewlet

In addition to a runtime render viewlet, you can also supply a placeholder viewlet so that you can customize the appearance of the placeholder that appears in the richeditor. The convention based viewlet path is `widgets.{widgetid}.placeholder`. For example:

```luceescript
// /handlers/widgets/FormBuilderForm.cfc
component {
    property name="formbuilderService" inject="formbuilderService";

    ...

    private string function placeholder( event, rc, prc, args={} ) {
        var fbForm          = formbuilderService.getForm( args.form ?: "" );
        var translationArgs = [ fbForm.name ?: "unknown form" ];

        if ( Len( Trim( args.instanceid ?: "" ) ) ) {
            translationArgs[1] &= " (" & args.instanceid & ")";
        }

        return translateResource( uri="widgets.FormBuilderForm:placeholder", data=translationArgs );
    }
}
```

## Filtering widgets in editors

As of Preside 10.7.0, you can limit the widgets that are selectable in a given richeditor. To do so, use the `widgetCategories` attribute of the [[formcontrol-richeditor]] form control. For example, in a form:

```xml
    <field name="newsletter_body" control="richeditor" widgetCategories="email,newsletter" />

    ...
```

Or, in a Preside Object:

```luceescript
property name="newsletter_body" type="string" dbtype="text" widgetCategories="email,newsletter";
```

If a widget does not specify any categories, a category of "default" will be used. Similarly, if no `widgetCategories` attribute is supplied for the richeditor control, it will be assumed to be "default". With this in mind, if you wish to have a widget categorised for specific scenarios, but also wish it to appear in default richeditor configurations, you should explicitly add the "default" category:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="widgets.myWidget:" categories="default,mySpecialCategory">
    <tab id="default">
        <!-- ... -->
```