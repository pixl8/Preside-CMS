---
id: formbuilder-overview
title: Form Builder overview
---

As of v10.5.0, PresideCMS provides a system that enables content administrators to build input forms to gather submissions from their site's user base.

![Screenshot showing a form builder form's workbench](images/screenshots/formbuilder_workbench.jpg)

## Enabling form builder

In version 10.5.0, the form builder system is disabled by default. To enable it, set the `enabled` flag on the `formbuilder` feature in your application's `Config.cfc$configure()` method:

```luceescript
component extends="preside.system.config.Config" {

	public void function configure() {
		super.configure();
		
		// ...

		// enable form builder
		settings.features.formbuilder.enabled = true;

		// ...
	}
}

```

## Forms

Forms are the base unit of the system. They can be created, configured, activated and locked by your system's content editors. Once created, they can be inserted into content using the Form Builder form widget. A form definition consists of some basic configuration and any number of ordered and individually configured items (e.g. a text input, select box and email address).

![Screenshot showing a list of form builder forms](images/screenshots/formbuilder_forms.jpg)

Useful references for extending the core form object and associated widget:

* [[presideobject-formbuilder_form|Form builder: form (Preside Object)]]
* [[form-formbuilderformaddform]]
* [[form-formbuilderformeditform]]
* [[form-widgetconfigurationformformbuilderform]]

## Form items and item types

Form items are what provide the input and display definition of the form. _i.e. a form without any items will be essentially invisible_. Content editors can drag and drop item types into their form definition; they can then configure and reorder items within the form definition. The configuration options and display of the item will differ for different item _types_.

![Screenshot showing a configuration of a date picker item](images/screenshots/formbuilder_configureitem.jpg)

The core system provides a basic set of item types whose configuration can be modified and extended by your application or extensions. You are also able to introduce new item types in your application or extensions.

See [[formbuilder-itemtypes]] for more detail.

## Form actions

Form actions are configurable triggers that are fired once a form has been submitted. The core system comes with a single 'Email' action that allows the CMS administrator to configure email notification containing the form submission.

![Screenshot showing a form builder actions workbench](images/screenshots/formbuilder_actions.jpg)

Developers can create their own custom actions that are then available to content editors to add to their forms. See [[formbuilder-actions]] for more detail.

## Form builder permissioning

Access to the Form Builder admin system can be controlled through the [[cmspermissioning]] system. The following access keys are defined:

* `formbuilder.navigate`
* `formbuilder.addform`
* `formbuilder.editform`
* `formbuilder.lockForm`
* `formbuilder.activateForm`
* `formbuilder.deleteSubmissions`
* `formbuilder.editformactions`

In addition, a `formbuildermanager` _role_ is defined that has access to all form builder operations:

```luceescript
settings.adminRoles.formbuildermanager = [ "formbuilder.*" ];
```

Finally, by default, the `contentadministrator` _role_ has access to all permissions with the exception of `lock` and `activate` form.

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