---
id: presideforms
title: Configuring and using forms
---

##Introduction
PresideCMS has a built-in forms service which takes care of the majority of form generation and validation requirements.
Below is a summary of the different apects and configuration options to be aware of when creating and configuring Preside Forms in your project.

You can configure forms for any of the following:

* Page types
* Preside objects (Data manager addd / edit pages)
* Widgets
* Notifications
* Rich editor
* System config
* Custom forms

##General form structure
<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Element</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
            <tr><td>Form</td><td>Single form specified in the view that will include the form.</td></tr>
            <tr><td>Tab *(Optional)*</td><td>One or more tabs configured in your specific form xml file</td></tr>
            <tr><td>Fieldset</td><td>One or more fieldsets configured in your specific form xml file</td></tr>
            <tr><td>Field</td><td>One or more form fields configured in your specific form xml file</td></tr>
        </tbody>
    </table>
</div>

###Configuration file paths
Form files should be created under the `/website/application/forms/` directory of your application.  E.g.

* `/website/application/forms/preside-objects/shop_product/admin.edit.xml`
* `/website/application/forms/shop/checkout.xml`

###File naming conventions
Preside uses the following conventions for naming your configuration files in the `/forms` directory.

####Preside objects
* `/preside-objects/{object_name}/admin.add.xml`
* `/preside-objects/{object_name}/admin.edit.xml`

####Page types
* `/page-types/{page_type}/add.xml` e.g. `/page-types/homepage/add.xml`
* `/page-types/{page_type}/edit.xml` e.g. `/page-types/homepage/edit.xml`
* `/page-types/{page_type}.xml` e.g. `/page-types/login.xml`

####Widgets
* `/widgets/{widget_name}.xml` e.g. `/widgets/whos_who.xml`

####System config
* `/system-config/{page_type}.xml` e.g. `/system-config/email.xml`

####Custom forms
* `/customFormFolder/custom-form-name.xml` e.g. `/eventBooking/deletgate.xml`

>>> Any of the references below to Title or Description can be controlled using the i18n properties files.

##Form definition file
Generally a form definition file will look something like the below system form for adding an asset to the CMS:

See [[form-assetaddform]] for detail.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form>
    <tab id="standard"
         sortorder="10"
         title="preside-objects.asset:standard.tab.title"
         description="preside-objects.asset:standard.tab.description">
         <fieldset id="standard" sortorder="10">
             <field sortorder="10" binding="asset.title"                           />
             <field sortorder="20" binding="asset.author"      control="textinput" />
             <field sortorder="30" binding="asset.description" control="textarea"  />
         </fieldset>
    </tab>
</form>
```

The different elements are described in more detail below.

##Tabs
Tabs define a tabbed content section.  The below specifys two form tabs.

```xml
<form>
    <tab id="standard"
         sortorder="10"
         title="preside-objects.myobject:standard.tab.title">
         ...
    </tab>
    <tab id="settings"
         sortorder="20"
         title="preside-objects.myobject:settings.tab.title"
         description="preside-objects.myobject:settings.tab.description">
         ...
    </tab>
</form>
```

###Available attributes
<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Attribute</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
            <tr><td>id</td><td>A unique identifier value for the tab, e.g. "standard"</td></tr>
            <tr><td>title</td><td>A value that will be used for the tab title text</td></tr>
            <tr><td>decription</td><td>A value that will be used for the tab and generally output within the tab content section</td></tr>
            <tr><td>sortorder</td><td>A value to determine the order in which the tab will be output</td></tr>
            <tr><td>deleted</td><td>A boolean value to determine whether or not to display the tab based on the id value</td></tr>
        </tbody>
    </table>
</div>

###Removing a tab
If you need to remove a tab from an existing form, for example the core `page` object located at:

`/system/forms/preside-objects/page/edit.xml`

You can simply create a corresponding configuration file within your project located at:
`/website/application/forms/preside-objects/page/edit.xml`

Then to remove the tab, use the `id` to target the required tab to be removed and specify the `deleted` attribute with a value of `true`.

```xml
<form>
    <tab id="dates" deleted="true" />
</form>
```

##Fieldsets
Fieldsets can be used to group associated form elements together and for styling these elements e.g. two column layout or multiple elements on a sinlge row.

```xml
<form>
	<tab id="addresses" title="system-config.email:addresses.tab.title">
		<fieldset id="addresses">
		    ...
		</fieldset>
	</tab>
</form>
```

###Available attributes
<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Attribute</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
            <tr><td>id</td><td>A unique identifier value for the fieldset, e.g. "main"</td></tr>
            <tr><td>title</td><td>A value that will be used for the fieldset title text</td></tr>
            <tr><td>decription</td><td>A value that will be used for the fieldset and generally output within the fieldset content section</td></tr>
            <tr><td>sortorder</td><td>A value to determine the order in which the fieldset will be output</td></tr>
            <tr><td>deleted</td><td>A boolean value to determine whether or not to display the fieldset based on the id value</td></tr>
        </tbody>
    </table>
</div>

You can also specify a custom layouts for your fieldsets, see below for detail on using layouts.

##Fields

```xml
<form>
	<tab id="addresses" title="system-config.email:addresses.tab.title">
        <field  name="groups_from_address"
                sortorder="10"
                control="textinput"
                required="false"
                label="system-config.email:groups_from_address.label"
                help="system-config.email:groups_from_address.help"
                placeholder="system-config.email:groups_from_address.placeholder"
        />

        <field  name="allow_users_access"
                sortorder="10"
                control="objectPicker"
                object="website_user"
                multiple="true"
                required="false"
                label="preside-objects.asset:field.allow_users_access.title"
                help="preside-objects.asset:field.allow_users_access.help"
        />

        <field sortorder="20" binding="page.slug" control="autoslug" required="true" basedOn="title" />

        <field sortorder="10" binding="page.parent_page" control="sitetreePagePicker" required="true" />

        <field binding="password_policy.min_strength" control="passwordStrengthPicker" />
    </tab>
</form>
```

##Form controls
There are a number of core controls you can select from, too many to mention here but you can see them all at:

`/handlers/formcontrols/`

`/views/formcontrols/`


##Layouts
Layouts can be used to provide custom markup to the form rendering engine to inject your dynamic content.

###Form


###Tab

###Fieldset

###Field


##Customising
Including passing custom attributes e.g. `additional_class` to control the look of the view by passing different class names


##Implementation


###renderFrom()

```html
<form action="#event.buildLink( linkTo='page-types.account_settings.updatePassword' )#">
    #renderForm(
          formName            = "accountSettings.changePassword"
        , context             = "website"
        , formId              = "changePassword"
        , validationResult    = rc.validationResult ?: ""
        , includeValidationJs = false
        , fieldsetLayout      = "formcontrols.layouts.accountSettingsForm.fieldset"
        , tabLayout           = "formcontrols.layouts.accountSettingsForm.tab"
        , formLayout          = "formcontrols.layouts.PACT_form"
        , fieldLayout         = "formcontrols.layouts.accountSettingsForm.field"
    )#

    <div class="button-holder">
        <input type="submit" class="button" value="Update">
    </div>
</form>
```

### event.getCollectionForForm


### event.getFormCollection()



## Form validation
(brief, with a link to a yet to be written page on our validation framework)


## Form features
Preside allows you to specify a form `feature` which can be used to control whether or not the foms should be enabled in the application

```xml
<form feature="websiteUsers">
	<tab id="main">
		<fieldset id="main">
			<field name="active"       deleted="true" />
			<field name="main_image"   deleted="true" />
			<field name="main_content" deleted="true" />
			<field name="teaser"       deleted="true" />
		</fieldset>
	</tab>

	<tab id="access" deleted="true" />
	<tab id="dates"  deleted="true" />
</form>
```

## Enabling / disabling features
The core `config.cfc` has a definition of the number of features which can be enabled / disabled on a per application basis.

```luceescript
settings.features = {
      sitetree              = { enabled=true , siteTemplates=[ "*" ] }
    // ...
    , multilingual          = { enabled=false, siteTemplates=[ "*" ] }
};
```

To enable / disable a feature in your application you can simply specify the following in your own application `config.cfc`

```luceescript
settings.features.websiteUsers = { enabled=false };
```


##Form preprocessing
More to follow on form preprocesors...


![Screenshot showing use of the keycode test tool](images/screenshots/discoverkeycode.png)





