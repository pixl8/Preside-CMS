---
id: emailRecipientTypes
title: Creating and configuring email recipient types
---

## Email recipient types

Defining and configuring recipient types allows your email editors to inject useful variables into their email templates. It also allows the system to keep a track of emails that have been sent to specific recipients and to use the correct email address for the recipient.

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
settings.email.templates.recipientTypes.eventDelegate   = {
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