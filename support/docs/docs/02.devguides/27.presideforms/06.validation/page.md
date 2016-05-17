---
id: presideforms-validation
title: Preside form validation
---

## Preside form validation

The [[presideforms]] integrates with the [[validation-framework]] to provide automatic *validation rulesets* for your preside form definitions and API methods to quickly and easily validate a submitted form (see [[presideforms-processing]]).

The validation rulesets are generated in two ways:

1. Common attributes on fields that lead to validation rules, e.g. `required`, `maxLength`, etc.
2. Explicit validation rules defined on fields

## Common attributes

The following attributes on field definitions will lead to automatic validation rules being defined for the field. Remember also that any attributes defined on a preside object property will be pulled into a field definition when using `<field binding="objectname.propertyname" />`.

### required

Any field with a `required="true"` flag will automatically have a `required` validator added to the forms ruleset.

### minLength

Any field with a numeric `minLength` attribute will automatically have a `minLength` validator added to the forms ruleset. If the field has both `minLength` and `maxLength`, it will instead have a `rangeLength` validator added.

### maxLength

Any field with a numeric `maxLength` attribute will automatically have a `maxLength` validator added to the forms ruleset. If the field has both `minLength` and `maxLength`, it will instead have a `rangeLength` validator added.

### minValue

Any field with a numeric `minValue` attribute will automatically have a `min` validator added to the forms ruleset. If the field has both `maxValue` and `minValue`, it will instead have a `range` validator added.

### maxValue

Any field with a numeric `maxValue` attribute will automatically have a `max` validator added to the forms ruleset. If the field has both `minValue` and `maxValue`, it will instead have a `range` validator added.

### format

If a string field has a `format` attribute, a pattern matching validation rule will be added.

### type

For preside object properties that are mapped to form fields, the data type will potentially have an associated validation rule that will be added for the field. For example, date fields will get a valid `date` validator.

### uniqueindexes

For preside object properties that are mapped to form fields and that define unique indexes, a `presideObjectUniqueIndex` validator will be automatically added. This validator is server-side only and ensure that the value in the field is unique and will not break the unique index constraint.

### passwordPolicyContext

If a password field has a `passwordPolicyContext` attribute, the field will validate against the given password policy. Current supported contexts are `website` and `admin`.

## Explicit validation rules

Explicit validation rules can be set on a field with the following syntax:

```xml
<field name="name" control="textinput" required="true" sortorder="20">
	<rule validator="match" message="formbuilder.item-types.formfield:validation.error.invalid.name.format">
		<param name="regex" value="^[a-zA-Z][a-zA-Z0-9_]*$" />
	</rule>
</field>
```

Each rule must specify a `validator` attribute that matches a registered [[validation-framework]] validator. An optional `message` attribute can also be supplied and this can be either a plain string message, or [[i18n]] resource URI for translation.

Any configuration parameters for the ruleset are then defined in child `param` tags that always have `name` and `value` attributes.