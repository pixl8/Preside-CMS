---
id: presideforms-dynamic
title: Dynamically generating Preside form definitions
---

## Dynamically generating Preside form definitions

As of PresideCMS v10.6.0, the [[api-formsservice]] provides a [[formsservice-createform]] method for dynamically creating forms without the need for an XML definition file. This can be useful in scenarios where the form can take on many different fields that will differ depending on the current user context.

Example usage:

```luceescript
var newFormName = formsService.createForm( function( formDefinition ){
	
	formDefinition.setAttributes(
		i18nBaseUri = "forms.myform:"
	);
	
	formDefinition.addField( 
		  tab       = "default"
		, fieldset  = "default"
		, name      = "title"
		, control   = "textinput"
		, maxLength = 100
		, required  = true
	);
	
	formDefinition.addField(
		  tab      = "default"
		, fieldset = "default"
		, name     = "body"
		, control  = "richeditor"
		, required = true		
	);

} );
```

As seen in the example above, the method works by supplying a closure that takes a [[api-formdefinition]] object as its argument. You can then use the [[api-formdefinition]] object to build your form definition (see [[api-formdefinition]] for full API documentation).

## Extending existing forms

As well as creating forms from scratch, you can also extend an existing form by supplying the `basedOn` argument:

```luceescript
var newFormName = formsService.createForm( basedOn="existing.form", generator=function( formDefinition ){
	
	formDefinition.addField( 
		  tab       = "default"
		, fieldset  = "default"
		, name      = "title"
		, control   = "textinput"
		, maxLength = 100
		, required  = true
	);
	
	// ...
} );
```

## Specifying a form name

By default, a form name will be generated for you and returned. If you wish, however, you can supply your own form name for the dynamically generated form:

```luceescript
formsService.createForm( basedOn="existing.form", formName="my.new.form", generator=function( formDefinition ){
	
	formDefinition.addField( 
		  tab       = "default"
		, fieldset  = "default"
		, name      = "title"
		, control   = "textinput"
		, maxLength = 100
		, required  = true
	);
	
	// ...
} );
```

>>>> Be careful when specifying a form name. Should two dynamically generated forms share the same name but have different form definitions, you will run into problems. Form names should be unique per distinct definition.