---
id: presideforms-i18n
title: Preside form definitions and i18n
---

## Preside form definitions and i18n

Labels, help and placeholders for form controls, tabs and fieldsets can all be supplied through i18n properties files using Preside's [[i18n|i18n]] system. Resource URIs can be supplied either directly in your form definitions or by using convention combined with the `i18nBaseUri` attribute on your `form` elements (see [[presideforms-anatomy]]).

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form>
	<!-- Example of direct supplying of i18n resource URI for tab title -->
	<tab id="default" title="system-config.mailchimp:tab.default.title">
		<!-- ... -->
	</tab>
</form>
```

## Convention based i18n URIs

### Tabs

Tabs can have translatable titles, descriptions and icon classes. Convention is as follows:

* **Title:** `{i18nBaseUri}`tab.`{id}`.title
* **Description:** `{i18nBaseUri}`tab.`{id}`.description
* **Icon class:** `{i18nBaseUri}`tab.`{id}`.iconClass

For example, given the form definition below, the following i18n properties file definition will supply title, description and icon class by convention:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="system-config.mailchimp:">
	<tab id="credentials">
		<!-- -->
	</tab>
</form>
```

```properties
# /i18n/system-config/mailchimp.properties
tab.credentials.title=Credentials
tab.credentials.description=Supply your API credentials to connect with your MailChimp account
tab.credentials.iconClass=fa-key
```

### Fieldsets

Fieldsets can have translatable titles and descriptions. Convention is as follows:

* **Title:** `{i18nBaseUri}`fieldset.`{id}`.title
* **Description:** `{i18nBaseUri}`fieldset.`{id}`.description

For example, given the form definition below, the following i18n properties file definition will supply title and description of the fieldset by convention:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="system-config.mailchimp:">
	<tab id="credentials">
		<fieldset id="credentials">
			<!-- -->
		</fieldset>
	</tab>
</form>
```

```properties
# /i18n/system-config/mailchimp.properties
fieldset.credentials.title=Credentials
fieldset.credentials.description=Supply your API credentials to connect with your MailChimp account
```

### Fields


Fields can have translatable labels, help and, for certain controls, placeholders. Convention is as follows:

* **Label:** `{i18nBaseUri}`field.`{name}`.title
* **Help:** `{i18nBaseUri}`field.`{name}`.help
* **Placeholder:** `{i18nBaseUri}`field.`{name}`.placeholder

For example, given the form definition below, the following i18n properties file definition will supply label, placeholder and help text:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="event-management.schedule-form:">
	<tab id="basic">
		<fieldset id="basic">
			<!-- -->
			<field name="session_title" control="textinput" />
			<!-- -->
		</fieldset>
	</tab>
</form>
```

```properties
# /i18n/event-management/session-form.properties
field.session_title.title=Session title
field.session_title.placeholder=e.g. 'Coffee and code'
field.session_title.help=Title for your session, will be displayed in public event listing pages
```

## Page types and Preside objects

Forms for page types and preside objects will have a _default_ `i18nBaseUri` set for them:

* **Page types:** page-types.`{pagetype}`:
* **Preside objects:** preside-objects.`{objectname}`:
