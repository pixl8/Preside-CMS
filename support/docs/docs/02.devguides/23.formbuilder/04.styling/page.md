---
id: formbuilder-styling-and-layout
title: Form Builder styling and layout
---

The form builder system allows you to provide custom layouts for:

1. Entire forms
2. Individual form items

These layouts can be used to give your content editors choice about the appearance of their forms.

## Form layouts

Custom form layouts are implemented as viewlets with the pattern `formbuilder.layouts.form.(yourlayout)`. Layouts are registered simply by implementing a viewlet with this pattern (as either a handler or view).

### The viewlet

The `args` struct passed to the viewlet will contain a `renderedForm` key that contains the form itself with all the rendered items and submit button. It will also be passed any custom arguments sent to the [[formbuilderservice-renderform]] method (e.g. custom configuration in the form builder form widget).

The default layout is implemented simply with a view:

```lucee
<!-- /views/formbuilder/layouts/form/default.cfm -->

<cfparam name="args.renderedForm" type="string">
<cfoutput>
	<div class="formbuilder-form form form-horizontal">
		#args.renderedForm#
	</div>
</cfoutput>
```

### i18n for layout name

For each custom layout that you provide, an entry should be added to the `/i18n/formbuilder/layouts/form.properties` file to provide a title for layout choice menus. For instance, if you created a layout called 'stacked', you would add the following:

```properties
# /i18n/formbuilder/layouts/form.properties

stacked.title=Stacked layout
```

## Item layouts

Form item layouts are implemented in a similar way to form layouts. Viewlets matching the pattern `formbuilder.layouts.formfields.(yourlayout)` will be automatically registered as _global_ layouts for _all_ form field items.

In addition, specific layouts for item types can also be implemented by creating viewlets that match the pattern, `formbuilder.layouts.formfields.(youritemtype).(yourlayout)`. If an item type specific layout shares the same name as a global form field layout, the item type specific layout will be used when rendering an item for that type.

### The viewlet

The item layout viewlet will receive an `args` struct with:

* `renderedItem`, the rendered form control
* `error`, any error message associated with the item
* all configuration options set on the item

The default item layout looks like:

```lucee
<cfparam name="args.renderedItem" type="string"  />
<cfparam name="args.label"        type="string"  />
<cfparam name="args.id"           type="string"  />
<cfparam name="args.error"        type="string"  default=""  />
<cfparam name="args.mandatory"    type="boolean" default="false" />

<cfoutput>
	<div class="form-group">
		<label class="col-sm-3 control-label no-padding-right" for="#args.id#">
			#args.label#
			<cfif IsTrue( args.mandatory )>
				<em class="required" role="presentation">
					<sup>*</sup>
					<span>#translateResource( "cms:form.control.required.label" )#</span>
				</em>
			</cfif>
		</label>

		<div class="col-sm-9">
			<div class="clearfix">
				#args.renderedItem#
				<cfif Len( Trim( args.error ) )>
					<label for="#args.id#" class="error">#args.error#</label>
				</cfif>
			</div>
		</div>
	</div>
</cfoutput>
```

### i18n for layout names

Human friendly names for layouts should be added to `/i18n/formbuilder/layouts/formfield.properties`. For example, if creating a "twocolumn" layout, you should add the following:

```properties
# /i18n/formbuilder/layouts/formfield.properties

twocolumn.title=Two column
```
