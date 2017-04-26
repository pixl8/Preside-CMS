---
id: presideforms-rendering
title: Rendering Preside form definitions
---

## Rendering Preside form definitions

Preside form definitions are generally rendered using `renderForm()`, a global helper method that is a proxy to the [[formsservice-renderform]] method of the [[api-formsservice]]. A minimal example might look something like:

```lucee
<form id="signup-form" action="#postAction#" class="form form-horizontal">
	#renderForm(
		  formName         = "events-management.signup"
		, context          = "admin"
		, formId           = "signup-form"
		, validationResult = rc.validationResult ?: ""
	)#

	<input type="submit" value="Go!" />
</form>
```

## Dynamic data

A common requirement is for dynamic arguments to be passed to the rendering of forms. For example, you may wish to supply editorially driven form field labels to a statically defined form. **As of 10.8.0**, this can be achieved by passing the `additionalArgs` argument to the `renderForm()` method:

```lucee
<cfscript>
    additionalArgs = {
    	  fields    = { firstname={ label=dynamicFirstnameLabel } }
    	, fieldsets = { personal={ description=dynamicPersonalFieldsetDescription } }
    	, tabs      = { basic={ title=dynamicBasicTabTitle } }
    };
</cfscript>

<form id="signup-form" action="#postAction#" class="form form-horizontal">
	#renderForm(
		  formName         = "events-management.signup"
		, context          = "admin"
		, formId           = "signup-form"
		, validationResult = rc.validationResult ?: ""
		, additionalArgs   = additionalArgs
	)#

	<input type="submit" value="Go!" />
</form>
```

The `additionalArgs` structure expects `fields`, `fieldsets` and `tabs` keys (all optional). To add args for a specific field, add a key under the `fields` struct that matches the field _name_. For fieldsets and tabs, use the _id_ of the entity to match.

## Rendering process and custom layouts

When a form is rendered using the [[formsservice-renderform]] method, its output string is built from the bottom up. At the bottom level you have field controls, followed by field layout, fieldset layouts, tab layouts and finally a form layout.

### Level 1: form control

The renderer for each individual field's _form control_ is calculated by the field definition and context supplied to the [[formsservice-renderform]] method, see [[presideforms-controls]] for more details on how form controls are rendered. 

Each field is rendered using its control and the result of this render is passed to the field layout (level 2, below).

### Level 2: field layout

Each rendered field control is passed to a field layout (defaults to `formcontrols.layouts.field`). This layout is generally responsible for outputting the field label and any error message + surrounding HTML to enable the field control to be displayed correctly in the current page.

The layout's viewlet is passed an `args.control` argument containing the rendered form control from "level 1" as well as any args defined on the field itself.

An alternative field layout can be defined either directly in the form definition or in the [[formsservice-renderform]] method. See examples below

```xml
...
<!-- alternative layout defined directly in form definition.
     custom 'twoColumnPosition' attribute will be passed 
     as arg to the layout -->
<field name="start_date" layout="formcontrols.layout.twoColumnFieldLayout" twoColumnPosition="left"  />
<field name="end_date"   layout="formcontrols.layout.twoColumnFieldLayout" twoColumnPosition="right" />
...
```

```lucee
<!-- alternative layout for entire form defined as argument -->
#renderForm(
	  formName         = "events-management.signup"
	, context          = "admin"
	, formId           = "signup-form"
	, validationResult = rc.validationResult ?: ""
	, fieldLayout      = "events-management.fieldLayout"
)#
```

#### Example viewlet

```lucee
<!-- /views/formcontrols/layout/field.cfm -->
<cfscript>
	param name="args.control"  type="string";
	param name="args.label"    type="string";
	param name="args.help"     type="string";
	param name="args.for"      type="string";
	param name="args.error"    type="string";
	param name="args.required" type="boolean";

	hasError = Len( Trim( args.error ) );
</cfscript>

<cfoutput>
	<div class="form-group<cfif hasError> has-error</cfif>">
		<label class="col-sm-2 control-label no-padding-right" for="#args.for#">
			#args.label#
			<cfif args.required>
				<em class="required" role="presentation">
					<sup><i class="fa fa-asterisk"></i></sup>
					<span>#translateResource( "cms:form.control.required.label" )#</span>
				</em>
			</cfif>

		</label>

		<div class="col-sm-9">
			<div class="clearfix">
				#args.control#
			</div>
			<cfif hasError>
				<div for="#args.for#" class="help-block">#args.error#</div>
			</cfif>
		</div>
		<cfif Len( Trim( args.help ) )>
			<div class="col-sm-1">
				<span class="help-button fa fa-question" data-rel="popover" data-trigger="hover" data-placement="left" data-content="#HtmlEditFormat( args.help )#" title="#translateResource( 'cms:help.popover.title' )#"></span>
			</div>
		</cfif>
	</div>
</cfoutput>
```

### Level 3: Fieldset layout

The fieldset layout viewlet is called for each fieldset in your form and is supplied with the following `args`:

* `args.content` containing all the rendered fields for the fieldset
* any args set directly on the fieldset element in the form definition

The default fieldset layout viewlet is "formcontrols.layouts.fieldset". You can define a custom viewlet either on the fieldset directly or by passing the viewlet to the [[formsservice-renderform]] method.

```xml
<!-- alternative layout defined directly in form definition.
     custom 'colour' attribute will be passed 
     as arg to the layout -->
<fieldset id="security" layout="formcontrols.layout.colouredFieldset" colour="blue">
	...
</fieldset>
...
```

```lucee
<!-- alternative layout for entire form defined as argument -->
#renderForm(
	  formName         = "events-management.signup"
	, context          = "admin"
	, formId           = "signup-form"
	, validationResult = rc.validationResult ?: ""
	, fieldsetLayout   = "events-management.fieldsetLayout"
)#
```

#### Example viewlet

```lucee
<!-- /views/formcontrols/layout/fieldset.cfm -->
<cfparam name="args.id"                 default="" />
<cfparam name="args.title"              default="" />
<cfparam name="args.description"        default="" />
<cfparam name="args.content"            default="" />

<cfoutput>
	<fieldset<cfif Len( Trim( args.id ) )> id="fieldset-#args.id#"</cfif>>
		<cfif Len( Trim( args.title ) )>
			<h3 class="header smaller lighter green">#args.title#</h3>
		</cfif>
		<cfif Len( Trim( args.description ) )>
			<p>#args.description#</p>
		</cfif>

		#args.content#
	</fieldset>
</cfoutput>
```

### Level 4: Tab layout

The tab layout viewlet is called for each tab in your form and is supplied with the following `args`:

* an `args.content` argument containing all the rendered fieldsets for the tab
* any args set directly on the tab element in the form definition

The default tab layout viewlet is "formcontrols.layouts.tab". You can define a custom viewlet either on the tab directly or by passing the viewlet to the [[formsservice-renderform]] method.

```xml
<!-- alternative layout defined directly in form definition.
     custom 'colour' attribute will be passed 
     as arg to the layout -->
<tab id="security" layout="custom.formlayouts.colouredTab" colour="blue">
	...
</tab>
...
```

```lucee
<!-- alternative layout for entire form defined as argument -->
#renderForm(
	  formName         = "events-management.signup"
	, context          = "admin"
	, formId           = "signup-form"
	, validationResult = rc.validationResult ?: ""
	, tabLayout        = "events-management.tabLayout"
)#
```

#### Example viewlet

```lucee
<!-- /views/formcontrols/layout/tab.cfm -->
<cfscript>
	id          = args.id          ?: CreateUUId();
	active      = args.active      ?: false;
	description = args.description ?: "";
	content     = args.content     ?: "";
</cfscript>

<cfoutput>
	<div id="tab-#id#" class="tab-pane<cfif active> active</cfif>">
		<cfif Len( Trim( description ) )>
			<p>#description#</p>
		</cfif>

		#content#
	</div>
</cfoutput>
```

### Level 4: Form layout

The form layout viewlet is called once per form and is supplied with the following `args`:

* an `args.content` argument containing all the rendered tabs for the form
* an `args.tabs` array of tabs for the form (can be used to render the tabs header for example)
* an `args.validationJs` argument containing validation JS string
* an `args.formId` argument, this will be the same argument passed to the [[formsservice-renderform]] method
* any args set directly on the form element in the form definition

The default form layout viewlet is "formcontrols.layouts.form". You can define a custom viewlet either on the form directly or by passing the viewlet to the [[formsservice-renderform]] method.

```xml
<!-- alternative layout defined directly in form definition  -->
<form layout="custom.formlayouts.formLayout">
	...
</form>
```

```lucee
<!-- alternative layout for entire form defined as argument -->
#renderForm(
	  formName         = "events-management.signup"
	, context          = "admin"
	, formId           = "signup-form"
	, validationResult = rc.validationResult ?: ""
	, formLayout       = "events-management.formLayout"
)#
```

#### Example viewlet

```lucee
<!-- /views/formcontrols/layout/form.cfm -->
<cfscript>
	tabs               = args.tabs         ?: [];
	content            = args.content      ?: "";
	validationJs       = args.validationJs ?: "";
	formId             = args.formId       ?: "";
</cfscript>

<cfoutput>
	<cfif ArrayLen( tabs ) gt 1>
		<div class="tabbable">
			<ul class="nav nav-tabs">
				<cfset active = true />
				<cfloop array="#tabs#" index="tab">
					<li<cfif active> class="active"</cfif>>
						<a data-toggle="tab" href="##tab-#( tab.id ?: '' )#">#( tab.title ?: "" )#</a>
					</li>
					<cfset active = false />
				</cfloop>
			</ul>

			<div class="tab-content">
	</cfif>

	#content#

	<cfif ArrayLen( tabs ) gt 1>
			</div>
		</div>
	</cfif>

	<cfif Len( Trim( formId ) ) and Len( Trim( validationJs ))>
		<cfsavecontent variable="validationJs">
			( function( $ ){
				$('###formId#').validate( #validationJs# );
			} )( presideJQuery );
		</cfsavecontent>
		<cfset event.includeInlineJs( validationJs ) />
	</cfif>
</cfoutput>
```