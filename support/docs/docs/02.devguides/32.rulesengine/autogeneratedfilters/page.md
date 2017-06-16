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