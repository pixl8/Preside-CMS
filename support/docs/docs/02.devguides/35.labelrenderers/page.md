---
id: labelrenderers
title: Label renderers
---

## Overview

When an [[formcontrol-objectPicker|Object Picker]] is displayed, by default the text on both the selectable and selected options is taken from the record's label (either the `label` field or whatever fields has been defined on the object using the `@labelField` annotation).

However, there are times when you will need more control over what gets displayed as the label. You might want to combine more than one field to identify the record accurately; you might even want to add an icon, picture or other HTML into the label.

Preside's custom label rendering (new in 10.8.0) allows you to do just this. Simply set up a label renderer handler in `/handlers/renderers/labels/`, and then either add the `labelRenderer` attribute to a field in your form definition, or - if you want this renderer to be used always for an object - via the `@labelRenderer` annotation on the preside object itself.

## Example

Let's say we are running an event, and the session categories are colour-coded. We might want to display that colour-coding in the object picker when selecting a category.

We would create a label renderer handler like this:

```luceescript
// /handlers/renderers/labels/session_category.cfc

component {

	private array function _selectFields( event, rc, prc ) {
		return [
			    "label"
			  , "colour"
		];
	}

	private string function _orderBy( event, rc, prc ) {
		return "label";
	}

	private string function _renderLabel( event, rc, prc ) {
		var label  = arguments.label ?: "";
		var colour = '<i style="display:inline-block;width:15px;height:15px;background-color:rgb(#arguments.colour#);"></i>';

		return colour & " " & htmlEditFormat( label );
	}

}
```

There are three methods defined in this handler.

`_selectFields()` should return an array of all the fields that will be required to build the label. They don't all have to come from the object in question - you can use fields from related objects, using the same `selectFields` syntax as if you were doing a `selectData()` call. In this case, we are retreiving the name of the category (stored in the object's `label` field) and the colour that has been assigned to it.

`_orderBy()` simply returns a string representing the SQL sort order that we want to use for the records in our object picker. In this case, we want them to be sorted by the category name. Again, this is just as in `selectData()`.

Finally, `_renderLabel()` defines how the various bits of data are combined to construct the label. Here we are creating a coloured square which is displayed in front of the category name.

>>>> If you are using a label renderer, the generated label will be output exactly as returned from this method (normally, labels are escaped before being displayed to allow for problematic characters). This means that you are responsible for ensuring that any text parts of the label are escaped as part of the `_renderLabel()` method. Here, we have used `htmlEditFormat()` to escape the category name.

All we need to do now is instruct your application to use our custom label renderer. In this case, we want to use this whenever this object appears in an object picker, so we will use an annotation:

```luceescript
// /preside-objects/session_category.cfc

/**
 * @labelRenderer session_category
 */

component  {
	property name="description" type="string" dbtype="text";
	property name="colour"      type="string" dbtype="varchar" maxlength=12 required=true;
}
```

If we only wanted to use it on a particular form, we would set it up in the form's XML definition:

```xml
<field binding="event_session.session_category" sortorder="10" labelRenderer="session_category" />
```

The resulting object picker would then look like this:

![Screenshot showing an object picker using a custom label renderer](images/screenshots/label-renderer-example.png)