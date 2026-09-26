# Email Templating System (v10.8.0+)

## Architecture Overview

```
Email Layout     →  Visual wrapper (header, footer, branding)
  └── Email Template  →  Content definition + parameter schema
        └── Recipient Type  →  Who receives it and how to address them
```

---

## Email Layouts

Layouts provide the HTML/text wrapper for all emails.

```cfm
<!-- /views/email/layout/default/html.cfm -->
<!DOCTYPE html>
<html>
<head><style>/* styles */</style></head>
<body>
    <header>
        <img src="#args.headerLogoUrl#" alt="Logo" />
    </header>
    <main>
        #args.body#
    </main>
    <footer>
        <p>#args.address#</p>
        <p><a href="#args.unsubscribeLink#">Unsubscribe</a></p>
        <p><a href="#args.viewOnlineLink#">View online</a></p>
    </footer>
</body>
</html>
```

```cfm
<!-- /views/email/layout/default/text.cfm -->
<cfoutput>
#args.body#

---
#args.address#
Unsubscribe: #args.unsubscribeLink#
</cfoutput>
```

Optional configuration form for layout settings:
```xml
<!-- /forms/email/layout/default.xml -->
<form i18nBaseUri="email.layout.default:">
    <tab id="default">
        <fieldset id="branding">
            <field name="header_logo"   control="assetPicker" allowedTypes="image" />
            <field name="footer_colour" control="simpleColourPicker" />
            <field name="address"       control="textarea" />
        </fieldset>
    </tab>
</form>
```

```properties
# /i18n/email/layout/default.properties
title=Default Email Layout
description=Standard branded email layout

field.header_logo.title=Header Logo
field.footer_colour.title=Footer Colour
field.address.title=Footer Address
```

---

## System Email Templates

Three parts: Config.cfc declaration, i18n properties, handler.

### 1. Config.cfc Declaration

```cfml
settings.email.templates.bookingConfirmation = {
      recipientType = "websiteUser"     // or custom recipient type
    , parameters    = [
          { id="event_name",      required=true  }
        , { id="booking_ref",     required=true  }
        , { id="booking_summary", required=false }
        , { id="edit_link",       required=false }
      ]
};
```

### 2. i18n Properties

```properties
# /i18n/email/template/bookingConfirmation.properties
title=Booking Confirmation
description=Sent to customers when they complete a booking

param.event_name.title=Event Name
param.event_name.description=The name of the event booked

param.booking_ref.title=Booking Reference
param.booking_summary.title=Booking Summary (HTML)
param.edit_link.title=Edit Booking Link
```

### 3. Handler

```cfml
// /handlers/email/template/BookingConfirmation.cfc
component {

    property name="bookingService" inject="bookingService";

    // Called at send time to resolve template parameters
    private struct function prepareParameters(
          required string bookingId    // These names must match args passed to $sendEmail()
    ) {
        var booking = bookingService.getBookingDetails( arguments.bookingId );

        return {
              event_name      = booking.event_name
            , booking_ref     = booking.reference
            , booking_summary = {
                  html = renderView( view="/email/template/bookingConfirmation/_summaryHtml", args={ booking=booking } )
                , text = renderView( view="/email/template/bookingConfirmation/_summaryText", args={ booking=booking } )
              }
            , edit_link = event.buildLink( linkTo="bookings.edit", queryString="id=#arguments.bookingId#" )
        };
    }

    // Shown in admin email template editor as preview
    private struct function getPreviewParameters() {
        return {
              event_name      = "Example Conference 2025"
            , booking_ref     = "BK-001234"
            , booking_summary = { html="<p>1 × Full Delegate Pass</p>", text="1 x Full Delegate Pass" }
            , edit_link       = "https://example.com/bookings/edit/?id=preview"
        };
    }

    // Default subject (editor can override)
    private string function defaultSubject() {
        return "Your booking confirmation for ${event_name} (Ref: ${booking_ref})";
    }

    // Default HTML body
    private string function defaultHtmlBody() {
        return renderView( view="/email/template/bookingConfirmation/_defaultHtmlBody" );
    }

    // Default plain text body
    private string function defaultTextBody() {
        return renderView( view="/email/template/bookingConfirmation/_defaultTextBody" );
    }

    // Optional: recipient address override
    private string function getToAddress( required string recipientId ) {
        return bookingService.getPrimaryEmail( arguments.recipientId );
    }
}
```

### Default Body View

```cfm
<!-- /views/email/template/bookingConfirmation/_defaultHtmlBody.cfm -->
<p>Dear ${recipient:first_name},</p>
<p>Thank you for booking <strong>${event_name}</strong>.</p>
<p>Your booking reference is: <strong>${booking_ref}</strong></p>
${booking_summary}
<p><a href="${edit_link}">Manage your booking</a></p>
```

Variable substitution in email bodies uses `${param_name}` syntax.
Recipient variables use `${recipient:property_name}`.

---

## Sending Emails

```cfml
// From a service/handler (PresideSuperClass):
$sendEmail(
      template    = "bookingConfirmation"
    , recipientId = websiteUserId            // Resolved by recipient type
    , args        = { bookingId=bookingId }  // Passed to prepareParameters()
);

// With explicit to address (bypasses recipient type lookup):
$sendEmail(
      template = "bookingConfirmation"
    , to       = "customer@example.com"
    , args     = { bookingId=bookingId }
);

// Send to multiple:
$sendEmail(
      template = "newsletter"
    , to       = [ "user1@example.com", "user2@example.com" ]
    , args     = {}
);

// With extra params:
$sendEmail(
      template    = "bookingConfirmation"
    , recipientId = userId
    , args        = { bookingId=bookingId }
    , params      = { additionalParam="value" }  // Extra template variables
);
```

---

## Recipient Types

Control how the email system resolves recipients.

### Built-in Recipient Types
- `websiteUser` — uses `website_user` object
- `adminUser` — uses `security_user` object
- `anonymous` — no recipient tracking

### Custom Recipient Type

```cfml
// Config.cfc
settings.email.recipientTypes.eventDelegate = {
      parameters            = [ "first_name", "last_name", "email_address" ]
    , filterObject          = "event_delegate"
    , gridFields            = [ "first_name", "last_name", "email_address" ]
    , recipientIdLogProperty = "event_delegate_recipient"
};
```

```cfml
// /handlers/email/recipientType/EventDelegate.cfc
component {

    property name="delegateService" inject="eventDelegateService";

    private struct function prepareParameters( required string recipientId ) {
        var delegate = delegateService.getDelegate( arguments.recipientId );
        return {
              first_name     = delegate.first_name
            , last_name      = delegate.last_name
            , email_address  = delegate.email_address
        };
    }

    private struct function getPreviewParameters() {
        return {
              first_name    = "Jane"
            , last_name     = "Doe"
            , email_address = "jane.doe@example.com"
        };
    }

    private string function getToAddress( required string recipientId ) {
        return delegateService.getDelegate( arguments.recipientId ).email_address;
    }

    // Optional: filter records for admin "send to segment" UI
    private struct function getFilterForBulkSend( event, rc, prc ) {
        return { filter={ active=true } };
    }
}
```

---

## Email Service Providers

Configure SMTP or third-party providers in the admin UI or Config.cfc:

```cfml
// Config.cfc - register a custom provider
settings.email.serviceProviders.myProvider = {
      configForm             = "email.serviceprovider.myProvider"
    , sendAction             = "email.serviceprovider.myProvider.send"
    , validateSettingsAction = "email.serviceprovider.myProvider.validateSettings"
};
```

```cfml
// /handlers/email/serviceProvider/MyProvider.cfc
component {

    private boolean function send( struct sendArgs={}, struct settings={} ) {
        var success = myProviderApi.sendMessage(
              apiKey  = settings.api_key
            , to      = sendArgs.to
            , from    = sendArgs.from
            , subject = sendArgs.subject
            , html    = sendArgs.htmlBody
            , text    = sendArgs.textBody
        );
        return success;
    }

    private any function validateSettings(
          required struct settings
        , required any    validationResult
    ) {
        if ( !Len(Trim(settings.api_key ?: "")) ) {
            validationResult.addError( "api_key", "email.myprovider:validation.api_key.required" );
        }
        return validationResult;
    }
}
```

---

## Email Interception Points

```cfml
component extends="coldbox.system.Interceptor" {
    public void function configure() {}

    // Modify send arguments before sending
    public void function onPrepareEmailSendArguments( event, interceptData ) {
        // interceptData.sendArgs = { to, from, subject, htmlBody, textBody, ... }
        interceptData.sendArgs.subject = "[ENV] " & interceptData.sendArgs.subject;
    }

    // Just before send
    public void function preSendEmail( event, interceptData ) {
        // interceptData.sendArgs, interceptData.settings
    }

    // After send (and after log entry)
    public void function postSendEmail( event, interceptData ) {
        logService.logEmailSent( interceptData.sendArgs );
    }
}
```

---

## Email Queue (Async Sending)

By default emails are sent synchronously. Enable queueing for async:

```cfml
settings.features.emailQueue.enabled    = true;
settings.features.emailQueueHeartBeat.enabled = true;  // Auto-processes queue
```
