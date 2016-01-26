---
id: formbuilder
title: Working with the Form Builder
---

## Introduction

As of v10.6.0, PresideCMS provides a system that enables content administrators to build input forms to gather submissions from their site's user base. The form builder system is fully extendable and this guide sets out to provide detailed instructions on how to do so.

>>>> The form builder system is not to be confused with the [[presideforms|PresideCMS Forms system]]. The form builder is a system in which content editors can produce dynamically configured forms and insert them into content pages. The [[presideforms|PresideCMS Forms system]] is a system of programatically defining forms that can be used either in the admin interface or hard wired into the application's front end interfaces.

## Forms

Forms are the base unit of the system. They can be created, configured, activated and locked by your system's content editors. Once created, they can be inserted into content using the Form Builder form widget. A form definition consists of some basic configuration and any number of ordered and individually configured items (e.g. a text input, captcha and submit button).

Useful references for extending the core form object and associated widget:

* [[presideobject-formbuilder_form|Form builder: form (Preside Object)]]
* [[form-formbuilderformaddform]]
* [[form-formbuilderformeditform]]
* [[form-widgetconfigurationformformbuilderform]]

## Form items and item types

Form items are what provide the input and display definition of the form. _i.e. a form without any items will be essentially invisible_. Content editors can drag and drop item types into their form definition; they can then configure and reorder items within the form definition. The configuration options and display of the item will differ for different item _types_.

The core system provides a basic set of item types who's configuration can be modified and extended by your application or extensions. You are also able to introduce new item types in your application or extensions.

### Anatomy of an item type

#### 1. Definition in Config.cfc

An item type must first be registered in the application or extension's `Config.cfc` file. Item types are grouped into item type categories which are used simply for display grouping in the form builder UI. The core definition looks something like this (subject to change):

```luceescript
settings.formbuilder = { itemtypes={} };

// The "standard" category
settings.formbuilder.itemTypes.standard = { sortorder=10, types={
      textinput    = { isFormField=true  }
    , textarea     = { isFormField=true  }
    , submitButton = { isFormField=false }
} };

// The "content" category
settings.formbuilder.itemTypes.content = { sortorder=20, types={
      spacer    = { isFormField=false }
    , content   = { isFormField=false }
} };

```

Introducing a new form field item type in the "standard" category might then look like this:

```luceescript
settings.formbuilder.itemTypes.standard.types.colourPicker = { isFormField = true };
```

#### 2. i18n labelling

The labels for item type categories are all defined in `/i18n/formbuilder/item-categories.properties`. Each category requires a "title" key, so:

```properties
standard.title=Standard form fields
content.title=Content and layout
```

Each item _type_ subsequently has it's own `.properties` file that lives at `/i18n/formbuilder/item-types/(itemtype).properties`. A bare minimum `.properties` file for an item type should define a `title` key, but it could also be used to define labels for the item type's configuration form. For example:

```properties
# /i18n/formbuilder/item-types/textarea.properties
title=Textarea

field.minlength.title=Minimum characters
field.minlength.help=Minimum character count for the textarea. Set to zero (0) for no limit.
field.maxlength.title=Maximum characters
field.maxlength.help=Maximum character count for the textarea. Set to zero (0) for no limit.
```

#### 3. Configuration form

An item type can _optionally_ have custom configuration options defined in a Preside form definnition. The form must live at `/forms/formbuilder/item-types/(itemtype).xml`. If the item type is a form field, this definition will be merged with the [[form-formbuilderitemtypeallformfields|core formfield configuration form]]. For example:

```xml
<!-- /forms/formbuilder/item-types/textarea.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="formbuilder.item-types.textarea:">
	<tab id="default">
		<fieldset id="default">
			<field name="minlength" control="spinner" required="false" sortorder="33" defaultvalue="0" />
			<field name="maxlength" control="spinner" required="false" sortorder="36" defaultvalue="0" />
		</fieldset>
	</tab>
</form>
```

#### 4. Form item renderer (for form input)

Each form item must define an "input" renderer so that the system knows how to display the item when rendering the form. This renderer is defined as a viewlet (see [[presideviewlets]]) using the convention: `formbuilder.item-types.(itemtype).renderInput`. For example, a "textarea" item type might define the viewlet in a handler, `/handlers/formbuider/item-types/Textarea.cfc`:

```luceescript
component {
	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "textarea"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}
}
```

The `args` struct passed to the viewlet will contain any saved configuration for the item (see "Configuration form" above), along with the following additional keys:

* **id:** A unique ID for the form item (calculated dynamically per request to ensure uniqueness)
* **error:** An error message. This may be supplied if the form has validation errors that need to be displayed for the item

An alternative example of an input renderer might be for an item type that is _not_ a form control, e.g. the 'content' item type. It's viewlet could be implemented simply as a view, `/views/formbuilder/item-types/content/renderInput.cfm`:

```lucee
<cfoutput>
	#renderContent( 
		  renderer = "richeditor"
		, data     = ( args.body ?: "" )
	)#
</cfoutput>
```

`args.body` is available to the item type because it is defined in it's configuration form.

#### 5. Response renderer (optional)

An item type can optionally supply a response renderer as a _viewlet_ matching the convention `formbuilder.item-types.(itemtype).renderResponse`. This renderer will be used to display the item as part of a form submission. If no renderer is defined, the system will fall back on the core viewlet, `formbuilder.defaultRenderers.response`.

TODO: provide example.

#### 6. Validation rule generator (optional)

TODO: provide docs on validation rule generation for an item type

#### 7. Item type layouts (optional)


## Form builder permissioning

Access to the Form Builder admin system can be controlled through the [[cmspermissioning]] system. The following access keys are defined:

* `formbuilder.navigate`
* `formbuilder.addform`
* `formbuilder.editform`
* `formbuilder.lockForm`
* `formbuilder.activateForm`
* `formbuilder.deleteSubmissions`

In addition, a `formbuildermanager` _role_ is defined that has access to all form builder operations:

```luceescript
settings.adminRoles.formbuildermanager = [ "formbuilder.*" ];
```

### Defining more restricted roles

In your own application, you could provide more fine tuned form builder access rules with configuration along the lines of the examples below:

```luceescript
// Adding perms to an existing role
settings.adminRoles.contenteditor.append( "formbuilder.*"                  );
settings.adminRoles.contenteditor.append( "!formbuilder.lockForm"          );
settings.adminRoles.contenteditor.append( "!formbuilder.activateForm"      );
settings.adminRoles.contenteditor.append( "!formbuilder.deleteSubmissions" );

// defining a new role
settings.adminRoles.formbuilderviewer = [ "formbuilder.navigate" ];

```