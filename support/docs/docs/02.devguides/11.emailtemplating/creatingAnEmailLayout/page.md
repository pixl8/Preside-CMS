---
id: creatingAnEmailLayout
title: Creating an email layout
---

>>> Email layouts were introduced in Preside 10.8.0. See [[emailtemplatingv2]] for more details.

## Creating an email layout

### 1. Create viewlets for HTML and plain text renders

Email layouts are created by convention. Each layout is defined as a pair of [[Viewlets|Preside viewlets]], one for the HTML version of the layout, another for the text only version of the layout. The convention based viewlet ids are `email.layout.{layoutid}.html` and `email.layout.{layoutid}.text`.

The viewlets receive three common variables in their `args` argument:

* `subject` - the email subject
* `body` - the main body of the email
* `viewOnlineLink` - a link to view the full email online (may be empty for transactional emails, for example)

In addition, the viewlets will also receive args from the layout's config form, if it has one (see 3, below).

A very simple example:

```lucee
<!-- /views/email/layout/default/html.cfm -->
<cfoutput><!DOCTYPE html>
<html>
    <head>
        <title>#args.subject#</title>
    </head>
    <body>
        <a href="#args.viewOnlineLink#">View in a browser</a>
        #args.body#
    </body>
</html>
</cfoutput>
```

```lucee
<!-- /views/email/layout/default/text.cfm -->
<cfoutput>
#args.subject#
#repeatString( '=', args.subject.len() )#

View online: #args.viewOnlineLink#

#args.body#
</cfoutput>
```

### 2. Provide translatable title and description

In addition to the viewlet, each layout should also have translation entries in a `/i18n/email/layout/{layoutid}.properties` file. Each layout should have a `title` and `description` entry. For example:

```properties
title=Transactional email layout
description=Use the transactional layout for emails that happen as a result of some user action, e.g. send password reminder, booking confirmation, etc.
```

### 3. Provide optional configuration form

If you want your application's content editors to be able to tweak layout options, you can also provide a configuration form at `/forms/email/layout/{layoutid}.xml`. This will allow end-users to configure global defaults for the layout and to tweak settings per email. For example:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="email.layout.transactional:">
    <tab id="default">
        <fieldset id="default" sortorder="10">
            <field name="twitterLink" />
            <field name="facebookLink" />
            <field name="address" control="textarea" />
        </fieldset>
    </tab>
</form>
```

With the form above, editors might be able to configure social media links and the company address that appear in the layout.