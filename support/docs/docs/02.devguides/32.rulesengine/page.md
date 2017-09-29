---
id: rulesengine
title: Rules engine
---

## Overview

As of Preside **10.7.0**, a standardised Rules Engine is provided by the core system. Currently, we provide a system for creating editorially configurable and complex _conditions_, several touch points for granting access to resources or content based on the evaluation of conditions, and APIs to use conditions in your custom application logic.

As of Preside **10.8.0**, the concept of _filters_ was also added to the rules engine along with auto generated expressions for preside objects. The rules engine is also now enabled by default (it was disabled by default in 10.7.0).

![Screenshot showing rule condition builder](images/screenshots/rulesEngineConditionBuilder.jpg)

## Terminology

### Conditions

Conditions are a user-configured combination of one or more logical _expressions_, grouped into sets that are combined with `and` or `or` joins. Administrative users of the platform can create conditions and save them with a unique name for later use in various scenarios, e.g. to grant access to a restricted page. Conditions are evaluated at runtime.

### Condition contexts

A condition context represents the context in which a condition will be run. For example, a "web request" condition can be evaluated in the context of a web request and a "user" condition can be evaluated in any context related to a single user.

Some contexts can encompass other contexts. For example, a "web request" context is expected to encompass "user" and "page" contexts with those contexts being populated with the currently logged in user, or visited page.

See [[rulesenginecontexts]] for a full guide.

### Filters

Similar to conditions, filters are a user-configured combination of one or more logical _filter_ expressions, grouped into sets that are combined with `and` or `or` joins. Administrative users of the platform can create filters and save them with a unique name for later use in various scenarios, e.g. to filter recordsets in admin data views, or for use in _conditions_ that control access to pages, etc.

Unlike conditions, filters must apply to a single [[dataobjects|preside data object]] and are used to create a database filter that is then applied to a [[presideobjectservice-selectdata]] query.

>>>>>> Filters can be used as conditions but conditions can not be used as filters.

### Expressions

Expressions are a single, configurable item that can be evaluated to true or false at runtime for conditions and/or evaluated to an array of preside object filters for use in filters.

Expressions are tied to one or more contexts so that only relevant expressions can be used to build a condition or filter that is targeted at a particular context. A context can be either a preside object or other custom / special contexts such as "webrequest".

The core system provides a basic set of expressions and developers are able to create additional expressions to enrich the system with customer-specific requirements. As of **10.8.0** the system also auto generates expressions to be used as filters for preside objects.

Expressions are combined by users to form conditions and filters. See [[rulesengineexpressions]] for a full guide.

### Expression fields

An expression can contain zero or more configurable fields that allow end-users to configure the expression in detail. A simple example:

```
user {_is} logged in
```

Here, the `{_is}` is an expression field that users can configure to be *is* or *is not*. More complex expressions can have many fields.

### Expression field types

Expression fields are typed so that the user experience of configuring the field can be tailored to the type of field. For example, `boolean` types are configured with just a single click to toggle them from `true` to `false`. `object` types will present the user with a record picker with data selected from the configured preside object for the field.

See [[rulesenginefieldtypes]] for a full guide.

![Screenshot showing configuration of an object type field](images/screenshots/rulesEngineObjectFieldConfiguration.jpg)


## Further reading

* [[rulesengineexpressions]]
* [[rulesenginefieldtypes]]
* [[rulesenginecontexts]]
* [[rulesengineapis]]
* [[rulesengineautogeneration]]

