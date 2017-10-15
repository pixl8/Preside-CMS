---
id: presideforms-controls
title: Preside form controls
---

## Preside form controls

Form controls are named [[viewlets|viewlets]] that are used for rendering form fields with the [[presideforms|Preside forms system]]. All form controls are implemented as viewlets whose path follows the convention `formcontrols.{nameofcontrol}.{renderercontext}`.

For a full reference list of core form controls, see [[systemformcontrols]].

### Renderer context

The _renderer context_ is a string value passed to the `renderForm()` method (see [[presideforms-rendering]]). The purpose of this is to allow form controls to have different viewlets for different contexts; i.e. an "admin" context for rendering controls in the admin vs a "website" context for rendering controls in the front end of your application.

At a bare minimum, form controls should implement a default "index" context for when there is no special renderer for specific contexts passed to `renderForm()`.

### Arguments

The `args` struct passed to your form control's viewlet will be a combination of:

* All attributes defined on the associated form `field` definition
* A `defaultValue` string that will be either the previously saved value for the field if there is one, _or_ the value of the `default` attribute set on the field definition
* An `error` string, populated if there are validation errors
* A `savedData` structure representing any saved data for the entire form
* A `layout` string that contains the viewlet that will be used to render the layout around the form control (this viewlet will usually take care of error messages and field labels, etc. see [[presideforms-rendering]])

### Examples

#### Simple textinput

A simple 'textinput' form control implemented as just a view (a viewlet without a handler) and with just a default "index" context:

```lucee
<!-- /views/formcontrols/textinput/index.cfm -->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder  = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<input type="text" id="#inputId#" placeholder="#placeholder#" name="#inputName#" value="#value#" class="#inputClass# form-control" tabindex="#getNextTabIndex()#">
</cfoutput>
```

#### Select with custom datasource

This example uses a handler based viewlet to retrieve data from a service with which to populate the standard `select` form control. The form control name is `derivativePicker`:


```luceescript
// /handlers/formcontrols/DerivativePicker.cfc
component {
	property name="assetManagerService"  inject="assetManagerService";

	public string function index( event, rc, prc, args={} ) {
		var derivatives = assetManagerService.listEditorDerivatives();

		if ( !derivatives.len() ) {
		    return ""; // do not render the control at all if no derivatives
		}

		// translate derivatives into labels and values for select control
		// including default 'none' derivative for picker
		args.labels       = [ translateResource( "derivatives:none.title" ) ];
		args.values       = [ "none" ];
		args.extraClasses = "derivative-select-option";

		for( var derivative in derivatives ) {
			args.values.append( derivative );
			args.labels.append( translateResource( uri="derivatives:#derivative#.title", defaultValue="derivatives:#derivative#.title" ) );
		}

		// render default select control using labels and values
		// calculated above
		return renderView( view="formcontrols/select/index", args=args );
	}
}
```