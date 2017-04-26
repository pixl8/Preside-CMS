---
id: systemEmailTemplates
title: Creating and sending system email templates
---

## System email templates

The development team may provide system transactional email templates such as "Reset password" or "Event booking confirmation". These templates are known as *system* templates and are available through the UI for content editors to _edit_; they cannot be created or deleted by content editors.

## Sending system email templates

System transactional emails are programatically sent using the [[emailservice-send]] method of the [[api-emailservice]] or the [[presidesuperclass-$sendemail]] method of the [[presidesuperclass|Preside super class]] (which proxies to the [[api-emailservice|emailService]].[[emailservice-send]] method).

While the [[emailservice-send]] method takes many arguments, these are chiefly for backwards compatibility. For sending the "new" (as of 10.8.0) style email templates, we only require three arguments:

```luceescript
$sendEmail(
	  template    = "bookingConfirmation"
	, recipientId = userId
	, args        = { bookingId=bookingId }
);
```

* `template` - ID of the configured template (see below)
* `recipientId` - ID of the recipient. The source object for this ID will differ depending on the [[emailRecipientTypes|recipient type]] of the email.
* `args` - Any additional data that the email template needs to render the correct information (see below)

## Creating system email templates

There are three parts to creating a system email template:

1. Declaration in Config.cfc
2. i18n `.properties` file for labelling
3. Hander to provide methods for generating email variables and default content

### 1. Config.cfc declaration

All system email templates must be registered in `Config.cfc`. An example configuration might look like this:

```luceescript
// register a 'bookingConfirmation' template:
settings.email.templates.bookingConfirmation = { 
	recipientType = "websiteUser", 
	parameters    = [
		  { id="booking_summary"  , required=true }
		, { id="edit_booking_link", required=false }
	]
};
```

#### Configuration options

* `recipientType` - each template _must_ declare a recipient type (see [[emailRecipientTypes]]). This is a string value and indicates the target recipients for the email template.
* `parameters` - an optional array of parameters that the template makes available for editors to be able insert into dynamic content. Each parameter is a struct with `id` and `required` fields.
* `feature` - an optional string value indicating the feature that the email template belongs to. If the feature is disabled, the template will not be available.

### 2. i18n .properties file

Each template should have a corresponding `.properties` file to provide labels for the template and any parameters that are declared. The file must live at `/i18n/email/template/{templateid}.properties`. An example:

```properties
title=Event booking confirmation
description=Email sent to customers who have just booked on an event

param.booking_summary.title=Booking summary
param.booking_summary.description=Booking summary text including tickets purchased, etc.

param.edit_booking_link.title=Edit booking link
param.edit_booking_link.description=A link to the page where delegate's can edit their booking
```

The template itself has a `title` and `description` key. Any defined parameters can also then have `title` and `description` keys, prefixed with `param.{paramid}.`.

### 3. Handler for generating parameters and defaults

The final part of creating a system transactional email template is the handler. This should live at `/handlers/email/template/{templateId}.cfc` and have the following signature:

```luceescript
component {

	private struct function prepareParameters() {}

	private struct function getPreviewParameters() {}

	private string function defaultSubject() {}

	private string function defaultHtmlBody() {}

	private string function defaultTextBody() {}

}
```

#### prepareParameters()

The `prepareParameters()` is where any real display and processing logic for your email template occurs; _email templates are only responsible for rendering parameters that are available for editors to use in their email content - **not** for rendering an entire email layout_.  The method should return a struct whose keys are the IDs of the parameters that are defined in `Config.cfc` (see above) and whose values are either:

* a string value to be used in both plain text and html emails
* a struct with `html` and `text` keys whose values are strings to be used in their respective email renders

The arguments passed to the `prepareParameters()` method will consist of any extra `args` that were passed to the [[emailservice-send]] method when the email was requested to be sent.

For example:

```luceescript
// send email call from some other service
emailService.send(
	  template    = "bookingConfirmation"
	, recipientId = userId
	, args        = { bookingId=bookingId } // used as the arguments set for the prepareParameters() call
);
```

```luceescript
// handlers/email/template/BookingConfirmation.cfc
component {

	property name="bookingService" inject="bookingService";
	
	// bookingId argument expected in `args` struct
	// in all `send()` calls for 'bookingConfirmation'
	// template
	private struct function prepareParameters( required string bookingId ) {
		var params = {};
		var args   = {};

		args.bookingDetails = bookingService.getBookingDetails( arguments.bookingId );

		params.eventName      = args.bookingDetails.event_name;
		params.bookingSummary = {
			  html = renderView( view="/email/template/bookingConfirmation/_summaryHtml", args=args )
			, text = renderView( view="/email/template/bookingConfirmation/_summaryText", args=args )
		};

		return params;
	}

	// ...
}
```

#### getPreviewParameters()

The `getPreviewParameters()` method has the exact same purpose as the `getParameters()` method _except_ that it should return a static set of parameters that can be used to preview the email template in the editing interface. It does not accept any arguments.

For example:

```luceescript
private struct function prepareParameters() {
	var params = {};
	var args   = {};

	args.bookingDetails = {
		  event_name = "Example event"
		, start_time = "09:00"
		// ... etc 
	};

	params.eventName      = "Example event";
	params.bookingSummary = {
		  html = renderView( view="/email/template/bookingConfirmation/_summaryHtml", args=args )
		, text = renderView( view="/email/template/bookingConfirmation/_summaryText", args=args )
	};

	return params;
}
```

#### defaultSubject()

The `defaultSubject()` method should return a **default** subject line to use for the email should an editor never have supplied one. e.g.

```luceescript
private struct function defaultSubject() {
	return "Your booking confirmation ${booking_no}";
}
```

This is _only_ used to populate the database the very first time that the template is detected by the application.

#### defaultHtmlBody()

The `defaultHtmlBody()` method should return a **default** HTML body to use for the email should an editor never have supplied one. e.g.

```luceescript
private struct function defaultHtmlBody() {
	return renderView( view="/email/template/bookingConfirmation/_defaultHtmlBody" );
}
```

You should create a sensible default that uses the configurable parameters just as an editor would do. This is _only_ used to populate the database the very first time that the template is detected by the application.


#### defaultTextBody()

The `defaultTextBody()` method should return a **default** plain text body to use for the email should an editor never have supplied one. e.g.

```luceescript
private struct function defaultTextBody() {
	return renderView( view="/email/template/bookingConfirmation/_defaultTextBody" );
}
```

You should create a sensible default that uses the configurable parameters just as an editor would do. This is _only_ used to populate the database the very first time that the template is detected by the application.
