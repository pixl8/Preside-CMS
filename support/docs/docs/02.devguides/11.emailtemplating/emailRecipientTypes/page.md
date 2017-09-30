---
id: emailRecipientTypes
title: Creating and configuring email recipient types
---

## Email recipient types

Defining and configuring recipient types allows your email editors to inject useful variables into their email templates. It also allows the system to keep track of emails that have been sent to specific recipients and to use the correct email address for the recipient.

## Configuring recipient types

There are up to four parts to configuring a recipient type:

1. Declaration in Config.cfc
2. i18n `.properties` file for labelling
3. Hander to provide methods for getting the address and variables for a recipient
4. (optional) Adding foreign key to the core [[presideobject-email_template_send_log]] object for your particular recipient type's core object

### 1. Config.cfc declaration

All email recipient types must be registered in `Config.cfc`. An example configuration might look like this:

```luceescript
// register an 'eventDelegate' recipient type:
settings.email.recipientTypes.eventDelegate   = {
	  parameters             = [ "first_name", "last_name", "email_address", "mobile_number" ]
	, filterObject           = "event_delegate"
	, gridFields             = [ "first_name", "last_name", "email_address", "mobile_number" ]
	, recipientIdLogProperty = "event_delegate_recipient"
};
```

#### Configuration options

* `parameters` - an array of parameters that are available for injection by editors into email content and subject lines
* `filterObject` - preside object that is the source object for the recipient, this can be filtered against for sending a single email to a large audience.
* `gridFields` - array of properties defined on the `filterObject` that should be displayed in the grid that shows when listing the potential recipients of an email
* `recipientIdLogProperty` - foreign key property on the [[presideobject-email_template_send_log]] object that should be used for storing the recipient ID in send logs (see below)
* `feature` - an optional string value indicating the feature that the recipient type belongs to. If the feature is disabled, the recipient type will not be available.

### 2. i18n property file

Each recipient type should have a corresponding `.properties` file to provide labels for the type and any parameters that are declared. The file must live at `/i18n/email/recipientType/{recipientTypeId}.properties`. An example:

```properties
title=Event delegate
description=Email sent to delegates of events

param.first_name.title=First name
param.first_name.description=First name of the delegate

# ...
```

The recipient type itself has a `title` and `description` key. Any defined parameters can also then have `title` and `description` keys, prefixed with `param.{paramid}.`.

### 3. Handler for generating parameters

Recipient types require a handler for returning parameters for a recipient and for returning the recipient's email address. This should live at `/handlers/email/recipientType/{recipientTypeId}.cfc` and have the following signature:

```luceescript
component {
	private struct function prepareParameters( required string recipientId ) {}

	private struct function getPreviewParameters() {}

	private string function getToAddress( required string recipientId ) {}
}
```

#### prepareParameters()

The `prepareParameters()` method should return a struct whose keys are the IDs of the parameters that are defined in `Config.cfc` (see above) and whose values are either:

* a string value to be used in both plain text and html emails
* a struct with `html` and `text` keys whose values are strings to be used in their respective email renders

The purpose here is to allow variables in an email's body and/or subject to be replaced with details of the recipient. The method accepts a `recipientId` argument so that you can make a DB query to get the required details. For example:

```luceescript
// handlers/email/recipientType/EventDelegate.cfc
component {

	property name="bookingService" inject="bookingService";
	
	private struct function prepareParameters( required string recipientId ) {
		var delegate = bookingService.getDelegate( arguments.recipientId );

		return {
			  first_name = delegate.first_name
			, last_name  = delegate.last_name
			// ... etc
		};
	}

	// ...
}
```

#### getPreviewParameters()

The `getPreviewParameters()` method has the exact same purpose as the `getParameters()` method _except_ that it should return a static set of parameters that can be used to preview any emails that are set to send to this recipient type. It does not accept any arguments.

For example:

```luceescript
private struct function prepareParameters() {
	return {
		  first_name = "Example"
		, last_name  = "Delegate"
		// ... etc
	};
}
```

#### getToAddress()

The `getToAddress()` method accepts a `recipientId` argument and must return the email address to which to send email. For example:

```luceescript
private struct function getToAddress( required string recipientId ) {
	var delegate = bookingService.getDelegate( arguments.recipientId );

	return delegate.email_address ?: "";
}
```

### 4. Email log foreign key

When email is sent through the [[emailservice-send|emailService.send()]] method, Preside keeps a DB log record for the send in the [[presideobject-email_template_send_log]] object. This record is used to track delivery, opens, clicks, etc. for the email.

In order to be able to later report on which recipients have engaged with email, you should add a foreign key property to the object that relates to the core object of your recipient type. For example, add a `/preside-objects/email_template_send_log.cfc` file to your application/extension:

```luceescript
/**
 * extend the core email_template_send_log object
 * to add our foreign key for event delegate recipient
 * type
 *
 */
component {
	// important: this must NOT be a required field
	property name="delegate_recipient" relationship="many-to-one" relatedto="event_delegate" required=false;
}
```

This extra property is then referenced in the configuration of your recipient type in your application's/extension's `Config.cfc` file (see above):

```luceescript
settings.email.templates.recipientTypes.eventDelegate   = {
	// ...
	, recipientIdLogProperty = "delegate_recipient"
};
```
