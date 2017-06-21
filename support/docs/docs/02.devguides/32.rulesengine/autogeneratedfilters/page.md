---
id: rulesengineautogeneration
title: Auto-generated filters
---

As of 10.8.0, Preside will auto generate basic filters for your preside objects. The system will iterate over your objects and generate multiple filter expressions for each of the object's properties.

## Bypassing filter expression generation

You can tell the system to NOT auto generate filter expressions for a property by adding the `autofilter=false` attribute to the property:

```luceescript
property name="description" ... autofilter=false;
```

## Auto-adding filters for related objects

The system can also add automatically generated filter expressions for `many-to-one` related objects. This means, for example, you can use filters for various `contact` object properties on a `user` object when the `user` object has a `many-to-one` relationship with `contact`.

The system will do this _automatically_ for any `many-to-one` relationships that also have a unique index (effectively a `one-to-one` relationship). However, you can also add the `autoGenerateFilterExpressions=true` attribute to the property to force this behaviour:

```luceescript
poperty name="category" relationship="many-to-one" autoGenerateFilterExpressions=true ...;
```

### Going multiple levels deep into relationships

If you want to auto generate filter expressions for related objects that are more than a single level deep, you can use the `@autoGenerateFilterExpressionsFor` attribute on the _object_ definition. 

For example, we may have the following related objects (each a `many-to-one` relationship): `event_delegate -> website_user -> contact -> organisation`. If we wanted our users to be able to easily filter `event_delegate` records by `contact` and `organisation` fields, we could add the `@autoGenerateFilterExpressionsFor` attribute as follows:

```luceescript
/**
 * event_delegate.cfc
 *
 * @autoGenerateFilterExpressionsFor website_user.contact, website_user.contact.organisation
 */
component {
	property name="website_user" relationship="many-to-one" relatedto="website_user";

	// ...
}
```

The syntax is a comma separated list of relationship chains that use the `many-to-one` property name at each stage of the relationship to define the path to the related object.

#### Customize the labeling used for multi-level filters

By default, auto generated filter expressions for related objects will be prefixed by the object name, e.g. `Organisation: city contains text`. 

However, you may find that you have multiple relationships to the same object and want to customize the prefix that appears to indicate which relationship is being filtered on. To do so, use the relationship path specified in your `@autoGenerateFilterExpressionsFor` attribute inside your object's i18n `.properties` file to provide an alternative:

```properties
filter.prefix.website_user.contact.organisation=User organisation
filter.prefix.sponsor.organisation=Sponsor organisation
```

>>> Each relationship path is prefixed with `filter.prefix.`.


## Customizing language for many-to-many and one-to-many filters

Auto-generated filter expressions for relationship fields look something like this (in English):

```
Attendee has any sessions
Attendee has (x) sessions
Attendee has sessions
```

This may be _ok_ in many scenarios, but we can customize this language slightly to make it more accurate by changing the `has` to something different. To do so, edit the `.properties` file for your preside object and add the following keys: `field.{relationshipPropertyName}.possesses.truthy` and `field.{relationshipPropertyName}.possesses.falsey`. e.g.

```properties
field.sessions.possesses.truthy=is signed up to
field.sessions.possesses.falsey=is not signed up to
```

This will then result in filter expressions that appear more naturally:

```
Attendee is signed up to any sessions
Attendee is signed up to (x) sessions
Attendee is signed up to sessions
```