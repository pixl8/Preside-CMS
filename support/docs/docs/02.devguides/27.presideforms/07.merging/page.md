---
id: presideforms-merging
title: Merging Preside form definitions
---

## Merging Preside form definitions

The [[presideforms]] provides logic for merging form definitions. This is used in two ways:

* Automatic merging of forms that match the same form ID but live in different locations (i.e. core, extensions, your application and site templates)
* Manual merging of multiple form definitions. For example, site tree page forms are merged from the core page form and form definitions for the page type of the page

## Automatic merging

One of the key features of PresideCMS is the ability to augment and override features defined in the core and in extensions. The forms system is no different and allows any form definition to be modified by extensions, your application and by site templates.

To modify an existing form definition, you must create a corresponding file under your application or extension's `/forms` directory. For example, if you wanted to modify the core [[form-assetaddform]] that lives at `/forms/preside-objects/asset/admin.add.xml`, you would create an xml file at `/application/forms/preside-objects/asset/admin.add.xml` within your application.

All form definitions that match by relative path will be merged to create a single definition.

## Manual merging

The [[api-formsservice]] provides several methods for dealing with combined form definitions. The key methods are:

* [[formsservice-mergeForms]], merges two forms and returns merged definition
* [[formsservice-getMergedFormName]], returns the registered name of two merged forms and optionally performs the merge if the merge has not already been made

## Merging techniques

### Adding form elements

Form elements can be added simply by defining distinct elements in the secondary form. For example:

```xml
<!-- form 1 -->
<?xml version="1.0" encoding="UTF-8"?>
<form>
	<tab id="default">
		<fieldset id="default" sortorder="10">
			<field name="myfield" />
		</fieldset>
	</tab>
</form>
```

```xml
<!-- form 2 -->
<?xml version="1.0" encoding="UTF-8"?>
<form>
	<tab id="default">
		<fieldset id="default">
			<!-- adds a new field in the pre-existing "default" fieldset and "default" tab -->
			<field name="newfield" />
		</fieldset>
		<!-- a new fieldset with field in the "default" tab -->
		<fieldset id="advanced">
			<field name="obscureSetting" />
		</fieldset>
	</tab>
	<!-- a new tab with fieldset and field -->
	<tab id="special">
		<fieldset id="special">
			<field name="isSpecial" control="yesNoSwitch" />
		</fieldset>
	</tab>
</form>
```

### Modifying existing elements

Tabs, fieldsets and fields that already exist in the primary form can be modified by defining elements that match `id` (fieldsets and tabs) or `name` (fields) and then defining new or different attributes. For example:

```xml
<!-- form 1 -->
<?xml version="1.0" encoding="UTF-8"?>
<form>
	<tab id="default" sortorder="10">
		<fieldset id="default" sortorder="10">
			<field name="myfield" control="textinput" required="false" />
		</fieldset>
	</tab>
</form>
```

```xml
<!-- form 2 -->
<?xml version="1.0" encoding="UTF-8"?>
<form>
	<!-- change the sortorder on the "default" tab -->
	<tab id="default" sortorder="20">
		<!-- add a layout attribute to the "default" fieldset -->
		<fieldset id="default" layout="custom.fieldsetLayout">
			<!-- make 'myfield' required and add a 'maxLength' rule -->
			<field name="myfield" required="true" maxlength="100" />
		</fieldset>
	</tab>
</form>
```

### Deleting elements

Elements that exist in the primary form definition can be deleted from the definition by adding a `deleted="true"` flag to element in the secondary form. For example:


```xml
<!-- form 1 -->
<?xml version="1.0" encoding="UTF-8"?>
<form>
	<tab id="default" sortorder="10">
		<fieldset id="default" sortorder="10">
			<field name="myfield" control="textinput" required="false" />
			<field name="another" control="textinput" required="false" />
		</fieldset>
		<fieldset id="special" sortorder="20">
			<field name="specialField" />
		</fieldset>
	</tab>
	<tab id="extra" sortorder="20">
		<fieldset id="extra" sortorder="10">
			<field name="extraField" />
		</fieldset>
	</tab>
</form>
```

```xml
<!-- form 2 -->
<?xml version="1.0" encoding="UTF-8"?>
<form>
	<tab id="default">
		<fieldset id="default">
			<!-- delete the "another" field -->
			<field name="another" deleted="true" />
		</fieldset>
		<!-- delete the entire "special" fieldset -->
		<fieldset id="special" deleted="true" />
	</tab>
	<!-- delete the entire "extra" tab -->
	<tab id="extra" deleted="true" />
</form>
```