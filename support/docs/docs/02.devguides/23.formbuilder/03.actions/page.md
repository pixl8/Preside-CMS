---
id: formbuilder-actions
title: Form Builder actions
---

Form actions are configurable triggers that are fired once a form has been submitted. The core system comes with a single 'Email' action that allows the CMS administrator to configure email notification containing the form submission.

![Screenshot showing a form builder actions workbench](images/screenshots/formbuilder_actions.jpg)

Developers can create their own custom actions that are then available to content editors to add to their forms.

# Creating a custom form action

## 1. Register the action in Config.cfc

Actions are registered in your application and extension's `Config.cfc` file as a simple array. To register a new 'webhook' action, simply append 'webhook' to the `settings.formbuilder.actions` array:

```luceescript
component extends="preside.system.config.Config" {

	public void function configure() {
		super.configure();


		// ...
		settings.formbuilder.actions.append( "webhook" );

		// ...
	}
}
```

## 2. i18n for titles, icons, etc.

Each registered action should have its own `.properties` file at `/i18n/formbuilder/actions/(action).properties`. It should contain `title`, `iconclass` and `description` keys + any other keys it needs for configuration forms, etc. For example, the `.properties` file for a "webhook" action might look like:

```
# /i18n/formbuilder/actions/webhook.properties

title=Webhook
iconclass=fa-send
description=Sends a POST request to the configured URL containing data about the submitted form

field.endpoint.title=Endpoint
field.endpoint.placeholder=e.g. https://mysite.com/formbuilder/webhook/
```

## 3. Create a configuration form

To allow editors to configure your action, supply a configuration form at `/forms/formbuilder/actions/(action).xml`. For example, the "email" configuration form looks like this:

```xml
<!-- /forms/formbuilder/actions/email.xml -->

<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="formbuilder.actions.email:">
	<tab id="default" sortorder="10">
		<fieldset id="default" sortorder="10">
			<field name="subject"    control="textinput" required="true"  />
			<field name="recipients" control="textinput" required="true"  />
			<field name="send_from"  control="textinput" required="false" />
		</fieldset>
	</tab>
</form>
```

![Screenshot showing a configuration of an email action](images/screenshots/formbuilder_configureaction.jpg)

## 4. Implement an onSubmit handler

The `onSubmit` handler is where your action processes the form submission and does whatever it needs to do. This handler will be a private method in `/handlers/formbuilder/actions/(youraction).cfc`. For example, the email action's submit handler looks like this:

```luceescript
component {

	property name="emailService" inject="emailService";

	// the args struct contains:
	// 
	// configuration  : struct of configuration options for the action
	// submissionData : the processed and saved data of the submission (struct)
	// 
	private void function onSubmit( event, rc, prc, args={} ) {
		emailService.send(
			  template = "formbuilderSubmissionNotification"
			, args     = args
			, to       = ListToArray( args.configuration.recipients ?: "", ";," )
			, from     = args.configuration.send_from ?: ""
			, subject  = args.configuration.subject ?: "Form submission notification"
		);
	}

}
```

## 5. Implement a placeholder viewlet (optional)

The placeholder viewlet allows you to customize how your configured action appears in the Form builder actions workbench:

![Screenshot showing the placeholder of a configured action](images/screenshots/formbuilder_actionplaceholder.jpg)

The viewlet called will be `formbuilder.actions.(youraction).renderAdminPlaceholder`. For the email action, this has been implemented as a handler method:

```luceescript
// /handlers/formbuilder/actions/Email.cfc

component {

	// ...

	private string function renderAdminPlaceholder( event, rc, prc, args={} ) {
		var placeholder = '<i class="fa fa-fw fa-envelope"></i> ';
		var toAddress   = HtmlEditFormat( args.configuration.recipients ?: "" );
		var fromAddress = HtmlEditFormat( args.configuration.send_from  ?: "" );

		if ( Len( Trim( fromAddress ) ) ) {
			placeholder &= translateResource(
				  uri  = "formbuilder.actions.email:admin.placeholder.with.from.address"
				, data = [ "<strong>#toAddress#</strong>", "<strong>#fromAddress#</strong>" ]
			);
		} else {
			placeholder &= translateResource(
				  uri  = "formbuilder.actions.email:admin.placeholder.no.from.address"
				, data = [ "<strong>#toAddress#</strong>" ]
			);
		}

		return placeholder;
	}
}
```