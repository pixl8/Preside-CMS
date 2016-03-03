---
id: formbuilder-itemtypes
title: Form Builder item types
---

Form items are what provide the input and display definition of the form. _i.e. a form without any items will be essentially invisible_. Content editors can drag and drop item types into their form definition; they can then configure and reorder items within the form definition. The configuration options and display of the item will differ for different item _types_.

![Screenshot showing a configuration of a date picker item](images/screenshots/formbuilder_configureitem.jpg)

The core system provides a basic set of item types who's configuration can be modified and extended by your application or extensions. You are also able to introduce new item types in your application or extensions.

# Anatomy of an item type

## 1. Definition in Config.cfc

An item type must first be registered in the application or extension's `Config.cfc` file. Item types are grouped into item type categories which are used simply for display grouping in the form builder UI. The core definition looks something like this (subject to change):

```luceescript
settings.formbuilder = { itemtypes={} };

// The "standard" category
settings.formbuilder.itemTypes.standard = { sortorder=10, types={
      textinput    = { isFormField=true  }
    , textarea     = { isFormField=true  }
    // ...
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

## 2. i18n labelling

The labels for each item type *category* are all defined in `/i18n/formbuilder/item-categories.properties`. Each category requires a "title" key:

```properties
standard.title=Basic
multipleChoice.title=Multiple choice
content.title=Content and layout
```

Each item _type_ subsequently has it's own `.properties` file that lives at `/i18n/formbuilder/item-types/(itemtype).properties`. A bare minimum `.properties` file for an item type should define a `title` and `iconclass` key, but it could also be used to define labels for the item type's configuration form. For example:

```properties
# /i18n/formbuilder/item-types/date.properties
title=Date
iconclass=fa-calendar

field.minDate.title=Minimum date
field.minDate.help=If entered, the input date must be greater than this date

field.maxDate.title=Maximum date
field.maxDate.help=If entered, the input date must be less than this date

field.relativeOperator.title=Relativity
field.relativeOperator.help=In what way should the value of this field be constrained in relation to the options below

field.relativeToCurrentDate.title=Current date
field.relativeToCurrentDate.help=Whether or not the date value entered into this field should be constrained relative to today's date

field.relativeToField.title=Another field in the form
field.relativeToField.placeholder=e.g. start_date
field.relativeToField.help=The name of the field who's value should be used as a relative constraint when validating the value of this field

tab.validation.title=Date limits
fieldset.fixed.title=Fixed dates
fieldset.relative.title=Relative dates

relativeOperator.lt=Less than...
relativeOperator.lte=Less than or equal to...
relativeOperator.gt=Greater than...
relativeOperator.gte=Greater than or equal to...
```

## 3. Configuration form

An item type can _optionally_ have custom configuration options defined in a Preside form definition. The form must live at `/forms/formbuilder/item-types/(itemtype).xml`. If the item type is a form field, this definition will be merged with the [[form-formbuilderitemtypeallformfields|core formfield configuration form]]. For example:

```xml
<!-- /forms/formbuilder/item-types/date.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="formbuilder.item-types.date:">
	<tab id="validation">
		<fieldset id="fixed">
			<field name="minDate" control="datePicker"  required="false"  sortorder="10" />
			<field name="maxDate" control="datePicker"  required="false"  sortorder="20" />
		</fieldset>
		<fieldset id="relative">
			<field name="relativeOperator"      control="select"      required="false"  sortorder="10" values=" ,lt,lte,gt,gte" labels=" ,formbuilder.item-types.date:relativeOperator.lt,formbuilder.item-types.date:relativeOperator.lte,formbuilder.item-types.date:relativeOperator.gt,formbuilder.item-types.date:relativeOperator.gte" defaultValue="" />
			<field name="relativeToCurrentDate" control="yesNoSwitch" required="false"  sortorder="20" />
			<field name="relativeToField"       control="textinput"   required="false"  sortorder="30" />
		</fieldset>
	</tab>
</form>
```

## 4. Handler actions and viewlets

The final component of a Form builder item is its handler. The handler must live at `/handlers/formbuilder/item-types/(itemtype).cfc` and can be used for providing one or more of the following:

1. `renderInput()`: a renderer for the form input (required),
2. `renderResponse()`: a renderer for a response (optional),
3. `renderResponseForExport()`: a renderer for a response in spreadsheet (optional),
4. `getExportColumns()`: logic to determine what columns are required in an spreadsheet export (optional),
5. `getItemDataFromRequest()`: logic to extract a submitted response from the request (optional),
6. `renderResponseToPersist()`: logic to render the response for saving in the database (optional),
7. `getValidationRules()`: logic to calculate what _validators_ are required for the item (optional)

### renderInput()

The `renderInput()` action is the only _required_ action for an item type and is used to render the item for the front end view of the form. A simple example:

```luceescript
// /handlers/formbuilder/item-types/TextArea.cfc
component {

	private string function renderInput( event, rc, prc, args={} ) {
		return renderFormControl(
			  argumentCollection = args
			, type               = "textarea"
			, context            = "formbuilder"
			, id                 = args.id ?: ( args.name ?: "" )
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}
}
```

The `args` struct passed to the viewlet will contain any saved configuration for the item (see "Configuration form" above), along with the following additional keys:

* **id:** A unique ID for the form item (calculated dynamically per request to ensure uniqueness)
* **error:** An error message. This may be supplied if the form has validation errors that need to be displayed for the item

#### renderInput.cfm (no handler version)

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

### renderResponse()

An item type can optionally supply a response renderer as a _viewlet_ matching the convention `formbuilder.item-types.(itemtype).renderResponse`. This renderer will be used to display the item as part of a form submission. If no renderer is defined, the system will fall back on the core viewlet, `formbuilder.defaultRenderers.response`.

An example of this is the `Radio buttons` control that renders the selected answer for an item:

```luceescript
// /handlers/formbuilder/item-types/Radio.cfc
component {
	// ...

	// args struct contains response (that is saved in 
	// the database) and itemConfiguration keys
	private string function renderResponse( event, rc, prc, args={} ) {
		var itemConfig = args.itemConfiguration ?: {};
		var response   = args.response;
		var values     = ListToArray( itemConfig.values ?: "", Chr( 10 ) & Chr( 13 ) );
		var labels     = ListToArray( itemConfig.labels ?: "", Chr( 10 ) & Chr( 13 ) );

		// loop through configured radio options
		for( var i=1; i<=values.len(); i++ ) {

			// find a match for the response
			if ( values[ i ] == response ) {

				// if label + value are different
				// include both the label and the value 
				// in the rendered response
				if ( labels.len() >= i && labels[ i ] != values[ i ] ) {
					return labels[ i ] & " (#values[i]#)";
				}

				// or just the value if same as label
				return response;
			}
		}

		// response did not match, just show
		// the saved response as is
		return response;
	}

	// ...
}
```

### renderResponseForExport()

This method allows you to render a response specifically for spreadsheet export. When used in conjunction with `getExportColumns()`, the result can be multiple columns of rendered responses.

For example, the `Matrix` item type looks like this:


```luceescript
// /handlers/formbuilder/item-types/Matrix.cfc
component {
	// ...

	// the args struct will contain response and itemConfiguration keys.
	// the response is whatever has been saved in the database for the item
	private array function renderResponseForExport( event, rc, prc, args={} ) {
		var qAndA = _getQuestionsAndAnswers( argumentCollection=arguments );
		var justAnswers = [];

		for( qa in qAndA ) {
			justAnswers.append( qa.answer );
		}

		// here we return an array of answers corresponding
		// to the question columns that we have defined
		// in the getExportColumns() method (see below)
		return justAnswers;
	}

	// ...

	// the args struct will contain the item's configuration
	private array function getExportColumns( event, rc, prc, args={} ) {
		var rows       = ListToArray( args.rows ?: "", Chr(10) & Chr(13) );
		var columns    = [];
		var itemName   = args.label ?: "";

		for( var row in rows ) {
			if ( !IsEmpty( Trim( row ) ) ) {
				columns.append( itemName & ": " & row );
			}
		}

		return columns;
	}

	// ...

	// this is just a specific utility method used by the matrix item type
	// to extract out questions and their answers from a saved response
	private array function _getQuestionsAndAnswers( event, rc, prc, args={} ) {
		var response   = IsJson( args.response ?: "" ) ? DeserializeJson( args.response ) : {};
		var itemConfig = args.itemConfiguration ?: {};
		var rows       = ListToArray( Trim( itemConfig.rows ?: "" ), Chr(10) & Chr(13) );
		var answers    = [];

		for( var question in rows ) {
			if ( Len( Trim( question ) ) ) {
				var inputId = _getQuestionInputId( itemConfig.name ?: "", question );

				answers.append( {
					  question = question
					, answer   = ListChangeDelims( ( response[ inputId ] ?: "" ), ", " )
				} );
			}
		}

		return answers;
	}
}
```

### getExportColumns()

This method allows us to define a custom set of spreadsheet export columns for a configured item type. This may be necessary if the item type actually results in multiple sub-questions being asked. You do _not_ need to implement this method for simple item types.

A good example of this is the `Matrix` item type that allows editors to configure a set of questions (rows) and a set of optional answers (columns). The `getExportColumns()` method for the `Matrix` item type looks like this:

```luceescript
// /handlers/formbuilder/item-types/Matrix.cfc
component {
	// ...

	// the args struct will contain the item's configuration
	private array function getExportColumns( event, rc, prc, args={} ) {
		var rows       = ListToArray( args.rows ?: "", Chr(10) & Chr(13) );
		var columns    = [];
		var itemName   = args.label ?: "";

		for( var row in rows ) {
			if ( !IsEmpty( Trim( row ) ) ) {
				columns.append( itemName & ": " & row );
			}
		}

		return columns;
	}
}
```

### getItemDataFromRequest()

This method allows us to extract out data from a form submission in a format that is ready for validation and/or saving to the database for our configured item. For simple item types, such as a text input, this is not necessary as we would simply need to take whatever value is submitted for the item.

An example usage is the `FileUpload` item type. In this case, we want to upload the file in the form field to a temporary location and return a structure of information about the file that can then be validated later in the request:

```luceescript
// /handlers/formbuilder/item-types/FileUpload.cfc
component {
	// ...

	// The args struct passed to the viewlet will contain inputName, requestData and itemConfiguration keys
	private any function getItemDataFromRequest( event, rc, prc, args={} ) {
		// luckily for us here, there is already a process that 
		// preprocesses a file upload and returns a struct of file info :)
		var tmpFileDetails = runEvent(
			  event          = "preprocessors.fileupload.index"
			, prePostExempt  = true
			, private        = true
			, eventArguments = { fieldName=args.inputName ?: "", preProcessorArgs={} }
		);

		return tmpFileDetails;
	}

	// ...
}
```


### renderResponseToPersist()

This method allows you to perform any manipulation on a submitted response for an item, _after_ form validation and _before_ saving to the database. For simple item types, such as a text input, this is generally not necessary as we can simply take whatever value is submitted for the item.

An example usage of this is the `FileUpload` item type. In this case, we want to take a temporary file and save it to storage, returning the storage path to save in the database:

```luceescript
// /handlers/formbuilder/item-types/FileUpload.cfc
component {
	// ...

	// The args struct passed to the viewlet will contain the submitted response + any item configuration
	private string function renderResponseToPersist( event, rc, prc, args={} ) {
		// response in this case will be a structure
		// containing information about the file
		var response = args.response ?: "";

		if ( IsBinary( response.binary ?: "" ) ) {
			var savedPath = "/#( args.formId ?: '' )#/#CreateUUId()#/#( response.tempFileInfo.clientFile ?: 'uploaded.file' )#";

			formBuilderStorageProvider.putObject(
				  object = response.binary
				, path   = savedPath
			);

			return savedPath;
		}

		return SerializeJson( response );
	}

	// ...
}
```

### getValidationRules()

This method should return an array of validation rules for the configured item (see [[validation-framework]] for full documentation on validation rules). These rules will be used both server-side, using the Validation framework, and client-side, using the jQuery Validate library, where appropriate.

>>> The core form builder system provides some standard validation rules for mandatory fields, min/max values and min/max lengths. You only need to supply validation rule logic for specific rules that your item type may require.

An example:

```luceescript
// /handlers/formbuilder/item-types/FileUpload.cfc
component {
	// ...

	// The args struct passed to the viewlet will contain any saved configuration for the item.
	private array function getValidationRules( event, rc, prc, args={} ) {
		var rules = [];

		// add a filesize validation rule if the item has
		// been configured with a max file size constraint

		if ( Val( args.maximumFileSize ?: "" ) ) {
			rules.append( {
				  fieldname = args.name ?: ""
				, validator = "fileSize"
				, params    = { maxSize = args.maximumFileSize }
			} );
		}

		return rules;
	}

	// ...
}
```
