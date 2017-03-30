---
id: emailtemplating
title: Email templating (pre-10.8.0)
---

## Overview

PresideCMS comes with a very simple email templating system that allows you to define email templates by creating ColdBox handlers.

Emails are sent through the core email service which in turn invokes template handlers to render the emails and return any other necessary mail parameters.

## Creating an email template handler

To create an email template handler, you must create a regular Coldbox handler under the `/handlers/emailTemplates` directory. The handler needs to implement a single *private* action, `prepareMessage()` that returns a structure containing any message parameters that it needs to set. For example:

```luceescript
// /mysite/application/handlers/emailTemplates/adminNotification.cfc
component {

    private struct function prepareMessage( event, rc, prc, args={} ) {
        return {
              to      = [ getSystemSetting( "email", "admin_notification_address", "" ) ]
            , from    = getSystemSetting( "email", "default_from_address", "" )
            , subject = "Admin notification: #( args.notificationTitle ?: '' )#"
            , htmlBody = renderView( view="/emailTemplates/adminNotification/html", layout="email", args=args )
            , textBody = renderView( view="/emailTemplates/adminNotification/text", args=args )
        };
    }

}
```

An example send() call for this template might look like this:

```luceescript
 emailService.send( template="adminNotification", args={
      notificationTitle   = "Something just happened"
    , notificationMessage = "Some message" 
} );
```

## Supplying message arguments to the send() method

Your email template handlers are not required to supply all the details of the message; these can be left to the calling code to supply. For example, we could refactor the above example so that the `to` and `subject` parameters need to be supplied by the calling code:

```luceescript
// /mysite/application/handlers/emailTemplates/adminNotification.cfc
component {

    private struct function prepareMessage( event, rc, prc, args={} ) {
        return {
              htmlBody = renderView( view="/emailTemplates/adminNotification/html", layout="email", args=args )
            , textBody = renderView( view="/emailTemplates/adminNotification/text", args=args )
        };
    }

}
```

```luceescript
emailService.send( 
      template = "adminNotification"
    , args     = { notificationMessage = "Some message" }
    , to       = user.email_address
    , subject  = "Alert: something just happend"
);
```

>>> Note the missing "from" parameter. The core send() implementation will attempt to use the system configuration setting `email.default_from_address` when encountering messages with a missing **from** address. This default address can be configured by users through the PresideCMS administrator (see [[editablesystemsettings]]).

## Mail server and other configuration settings

The core system comes with a system configuration form for mail server settings. See [[editablesystemsettings]] for more details on how this is implemented.

The system uses these configuration values to set the server and port when sending emails. The "default from address" setting is used when sending mail without a specified from address.

This form may be useful to extend in your site should you want to configure other mail related settings. i.e. you might have default "to" addresses for particular admin notification emails, etc.




