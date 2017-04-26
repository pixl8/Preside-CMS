---
id: emailServiceProviders
title: Creating email service providers
---

## Email service providers

Email service providers perform the task of sending email. Preside comes with a standard SMTP service provider that sends mail through `cfmail`. Service providers can be configured through the email centre admin UI.

## Creating an email service provider

There are four parts to creating a service provider:

1. Declaration in Config.cfc
2. i18n `.properties` file for labelling
3. xml form definition for configuring the provider
4. Handler to provide methods for sending and for validating settings

### Declaration in Config.cfc

A service provider must be defined in Config.cfc. Here are a couple of 'mailchimp' examples:

```luceescript
// use defaults for everything (recommended):
settings.email.serviceProviders.mailchimp = {};

// or, all options (with defaults):
settings.email.serviceProviders.mailchimp = {
      configForm             = "email.serviceprovider.mailchimp"
    , sendAction             = "email.serviceprovider.mailchimp.send"
    , validateSettingsAction = "email.serviceprovider.mailchimp.validateSettings"
};
```

#### Configuration options

* `configForm` - path to [[presideforms|xml form definition]] for configuring the provider
* `sendAction` - coldbox handler action path of the handler action that performs the sending of email
* `validateSettingsAction` - optional coldbox handler action path of the handler action that will perform validation against user inputted provider settings (using the config form)

### i18n .properties file

Each service provider should have a corresponding `.properties` file to provide labels for the provider and any configuration options in the config form. The default locaion is `/i18n/email/serviceProvider/{serviceProviderId}.properties`. An example:

```properties
title=MailGun
description=A sending provider for that sends email through the MailGun sending API
iconclass=fa-envelope

# config form labels:

fieldset.default.description=Note that we do not currently send through the mailgun API due to performance issues (it is far slower than sending through native SMTP). Retrieve your SMTP details from the mailgun web interface and enter below.

field.server.title=SMTP Server
field.server.placeholder=e.g. smtp.mailgun.org
field.port.title=Port
field.username.title=Username
field.password.title=Password

field.mailgun_test_mode.title=Test mode
field.mailgun_test_mode.help=Whether or not emails are actually sent to recipients or sending is only faked.

```

The only required keys are `title`, `description` and `iconclass`. Keys for your form definition are up to you.

### Configuration form

Service providers are configured in the email centre:


![Screenshot showing email service provider configuration](images/screenshots/emailServiceProviderSettings.png)


In order for this to work, you must supply a configuration form definition. The default location for your service provider's configuration form is `/forms/email/serviceProvider/{serviceProviderId}.xml`. An example:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="email.serviceProvider.mailgun:">
    <tab id="default">
        <fieldset id="default">
            <field name="server"            control="textinput"   required="false" default="smtp.mailgun.org" />
            <field name="port"              control="spinner"     required="false" default="587" minvalue="1" maxValue="99999" />
            <field name="username"          control="textinput"   required="false" />
            <field name="password"          control="password"    required="false" outputSavedValue="true" />
            <field name="mailgun_api_key"   control="textinput"   required="false" />
            <field name="mailgun_test_mode" control="yesNoSwitch" required="false" />
        </fieldset>
    </tab>
</form>
```

### Handler

Your service provider must provide a handler with at least a `send` action + an optional `validateSettings()` action. The default location of the file is `/handlers/email/serviceProvider/{serviceProviderId}.cfc`. The method signatures look like this:

```luceescript
component {
    
    private boolean function send( struct sendArgs={}, struct settings={} ) {}

    private any function validateSettings( required struct settings, required any validationResult ) {}

}
```

#### send()

The send method accepts a structure of `sendArgs` that contain `recipient`, `subject`, `body`, etc. and a structure of `settings` that are the saved configuration settings of your service provider. The method should return `true` if sending was successful.

The code listing below shows the core SMTP send logic at the time of writing this doc:

```luceescript
private boolean function send( struct sendArgs={}, struct settings={} ) {
    var m           = new Mail();
    var mailServer  = settings.server      ?: "";
    var port        = settings.port        ?: "";
    var username    = settings.username    ?: "";
    var password    = settings.password    ?: "";
    var params      = sendArgs.params      ?: {};
    var attachments = sendArgs.attachments ?: [];

    m.setTo( sendArgs.to.toList( ";" ) );
    m.setFrom( sendArgs.from );
    m.setSubject( sendArgs.subject );

    if ( sendArgs.cc.len()  ) {
        m.setCc( sendArgs.cc.toList( ";" ) );
    }
    if ( sendArgs.bcc.len() ) {
        m.setBCc( sendArgs.bcc.toList( ";" ) );
    }
    if ( Len( Trim( sendArgs.textBody ) ) ) {
        m.addPart( type='text', body=Trim( sendArgs.textBody ) );
    }
    if ( Len( Trim( sendArgs.htmlBody ) ) ) {
        m.addPart( type='html', body=Trim( sendArgs.htmlBody ) );
    }
    if ( Len( Trim( mailServer ) ) ) {
        m.setServer( mailServer );
    }
    if ( Len( Trim( port ) ) ) {
        m.setPort( port );
    }
    if ( Len( Trim( username ) ) ) {
        m.setUsername( username );
    }
    if ( Len( Trim( password ) ) ) {
        m.setPassword( password );
    }

    for( var param in params ){
        m.addParam( argumentCollection=sendArgs.params[ param ] );
    }
    for( var attachment in attachments ) {
        var md5sum   = Hash( attachment.binary );
        var tmpDir   = getTempDirectory() & "/" & md5sum & "/";
        var filePath = tmpDir & attachment.name
        var remove   = IsBoolean( attachment.removeAfterSend ?: "" ) ? attachment.removeAfterSend : true;

        if ( !FileExists( filePath ) ) {
            DirectoryCreate( tmpDir, true, true );
            FileWrite( filePath, attachment.binary );
        }

        m.addParam( disposition="attachment", file=filePath, remove=remove );
    }

    sendArgs.messageId = sendArgs.messageId ?: CreateUUId();

    m.addParam( name="X-Mailer", value="PresideCMS" );
    m.addParam( name="X-Message-ID", value=sendArgs.messageId );
    m.send();

    return true;
}
```

#### validateSettings()

The `validateSettings()` method accepts a `settings` struct that contains the user-defined settings submitted with the form, and a [[api-validationresult|validationResult]] object for reporting errors. It must return the passed in `validationResult`.

The core SMTP provider, for example, validates the SMTP server:

```luceescript
private any function validateSettings( required struct settings, required any validationResult ) {
    if ( IsTrue( settings.check_connection ?: "" ) ) {
        var errorMessage = emailService.validateConnectionSettings(
              host     = arguments.settings.server    ?: ""
            , port     = Val( arguments.settings.port ?: "" )
            , username = arguments.settings.username  ?: ""
            , password = arguments.settings.password  ?: ""
        );

        if ( Len( Trim( errorMessage ) ) ) {
            if ( errorMessage == "authentication failure" ) {
                validationResult.addError( "username", "email.serviceProvider.smtp:validation.server.authentication.failure" );
            } else {
                validationResult.addError( "server", "email.serviceProvider.smtp:validation.server.details.invalid", [ errorMessage ] );
            }
        }
    }

    return validationResult;
}
```

>>>>>> You are only required to supply custom validation logic here; you do **not** have to provide regular form validation logic that is automatically handled by the regular [[presideforms]] validation system.


