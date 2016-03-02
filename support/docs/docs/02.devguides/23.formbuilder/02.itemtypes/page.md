---
id: formbuilder-itemtypes
title: Form Builder item types
---



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