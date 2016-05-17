---
id: presideforms-features
title: Restricting Preside form elements by feature
---

## Restricting Preside form elements by feature

PresideCMS has a concept of features that are configurable in your application's `Config.cfc`. Features can be enabled and disabled for your entire application, or individual site templates. This can be useful for turning off core features, or features in extensions.

In the PresideCMS forms system, you can tag your forms, tabs, fieldsets and fields with feature names so that those elements are removed from the form definition when the feature is disabled.

### Examples

Tag an entire form with a feature ("cms"). If the feature is turned off, the entire form will be removed from the library of forms in the system:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form feature="cms">
	<!-- ... -->
</form>
```

Remove a _tab_ in a form when the "websiteusers" feature is disabled:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form>
	<!-- ... -->
	<tab id="access" feature="websiteusers">
		<!-- ... -->
	</tab>
</form>
```


Remove a _fieldset_ in a form when the "websiteusers" feature is disabled:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form>
	<!-- ... -->
	<tab id="access">
		<fieldset id="general">
			<!-- ... -->
		</fieldset>
		<fieldset id="users" feature="websiteusers">
			<!-- ... -->
		</fieldset>
	</tab>
</form>
```

Remove a _field_ in a form when the "websiteusers" feature is disabled:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form>
	<!-- ... -->
	<tab id="access">
		<fieldset id="access">
			<field name="country_restriction" ... />
			<field name="website_benefit" feature="websiteusers" />
		</fieldset>
	</tab>
</form>
```