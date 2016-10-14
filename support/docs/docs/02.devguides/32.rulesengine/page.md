---
id: rulesengine
title: Preside Rules Engine
---

As of Preside 10.7.0, a standardised Rules Engine is provided by the core system. Currently, we provide a system for creating editorially configurable and complex _conditions_, several touch points for granting access to resources or content based on the evaluation of conditions, and APIs to use conditions in your custom application logic.

![Screenshot showing rule condition builder](images/screenshots/rulesEngineConditionBuilder.jpg)

>>> The rules engine feature is currently turned off by default in Preside applications. To enable it, add the following line to your application's `Config.cfc$configure()` method: `features.rulesEngine.enabled = true`.

## Terminology

### Conditions

Conditions are a user-configured combination of one or more logical expressions, grouped into sets that are combined with `and` or `or` joins. Administrative users of the platform can create conditions and save them with a unique name for later use in various scenarios, e.g. to grant access to a restricted page.

### Condition contexts

A condition context represents the context in which a condition will be run. For example, a "web request" condition can be evaluated in the context of a web request and a "user" condition can be evaluated in any context related to a single user.

Some contexts can encompass other contexts. For example, a "web request" context is expected to encompass "user" and "page" contexts with those contexts being populated with the currently logged in user, or visited page.

### Expressions

Expressions are a single, configurable item that can be evaluated to true or false at runtime. Expressions are tied to a context so that only relevant expressions can be used to build a condition that is targeted at a particular context. The core system provides a basic set of expressions and developers are able to create additional expressions to enrich the system with customer-specific requirements.

Expressions are combined by users to form conditions.

### Expression fields

An expression can contain zero or more configurable fields that allow end-users to configure the expression in detail. A simple example:

```
user {_is} logged in
```

Here, the `{_is}` is an expression field that users can configure to be *is* or *is not*. More complex expressions can have many fields.

### Expression field types

Expression fields are typed so that the user experience of configuring the field can be taylored to the type of field. For example, `boolean` types, are configured with just a single click to toggle them from `true` to `false`. `object` types will present the user with a record picker with data selected from the configured preside object for the field.

![Screenshot showing configuration of an object type field](images/screenshots/rulesEngineObjectFieldConfiguration.jpg)

## Creating a rules engine expression

Rules engine expressions are a combination of an i18n resource file (`.properties` file) and a convention based handler that implements an `evaluateExpression` action.

>>> An expression can be scaffolded using the dev console `new ruleexpression` command


### i18n resource file

By convention, expression resource files must live at: `/i18n/rules/expressions/{idofexpression}.properties`. This file must, at a minimum, declare two keys, `label` and `text`:

```properties
label=User cancelled their place on an event
text=User {_has} cancelled their place on the event: {emsEvent}
```

The `label` item is used in the expression library selection box:

![Screenshot showing expression library selection box](images/screenshots/rulesEngineExpressionLibrary.jpg)

The `text` item is used in the condition builder, with `{somevar}` placeholders switched out for configurable fields:

![Screenshot showing expression being configured in condition builder](images/screenshots/rulesEngineExpressionInBuilder.jpg)

Default expression field texts (for required fields that have yet to be configured) can also be declared by convention in the `.properties` file. In the example above, the `{emsEvent}` field label is declared thus:

```properties
label=User cancelled their place on an event
text=User {_has} cancelled their place on the event: {emsEvent}

field.emsEvent.label=select an event
```

>>> Note the `{_has}` field. Chances are, if a field starts with an underscore, `_`, it is a "magic" system field that is automatically configured for you. See "Magic field names", below.

### The evaluateExpression handler action

Each expression must implement a handler with an `evaluateExpression` action (method) that returns `true` or `false` depending on the payload and configured expression field values. The handler must live at `/handlers/rules/expressions/{idOfExpression}.cfc`:

```luceescript
// /handlers/rules/expressions/userIsLoggedIn.cfc
/**
 * Expression handler for "User is/is not logged in"
 *
 * @feature websiteUsers
 * @expressionContexts webrequest
 */
component {

    private boolean function evaluateExpression( boolean _is=true ) {
        return arguments._is == isLoggedIn();
    }

}
```

#### Expression context

The handler CFC file can be annotated with an `expressionContexts` attribute that will define in what contexts the expression can be used.

#### Arguments passed to the evaluateExpression method

Becuase it is a ColdBox handler action, the method will always receive `event`, `rc` and `prc` arguments for you to use when relevant. In addition, the method will also always receive a `payload` argument that is a structure containing data relevant to the _context_ in which the expression is being evaluated. For example, the **webrequest** context provides a payload with `page` and `user` keys, each with a structure containing details of the current page and logged in user, respectively.

Any further arguments are treated as **expression fields** and should map to the `{placeholder}` fields defined in your expression resource file's `text` key. These arguments can also be decorated to further configure the field. For example, you may wish to define the field type + any further arguments that the field type requires:

```luceescript
/**
 * @expressionContexts user
 */
component {

    property name="emsUserQueriesService" inject="emsUserQueriesService";

    /**
     * @emsEvent.fieldType object
     * @emsEvent.object    ems_event
     * @emsEvent.multiple  false
     *
     */
    private boolean function evaluateExpression(
          required string  emsEvent
        ,          boolean _has = true
    ) {
        var userId = payload.user.id ?: "";

        if ( !userId.len() || !emsEvent.len() ) {
            return !_has;
        }

        var hasCancelled = emsUserQueriesService.userHasCancelledAttendance( userId, emsEvent );

        return hasCancelled == _has;
    }

}

```

Notice the annotations around the `emsEvent` argument above. Here they define the `object` field type and specify that the object for the field type is `ems_event` and that multiple selection is turned off.

>>>>>> We prefer to leave the `event`, `rc`, `prc` and `payload` arguments out of the function definition to more cleanly show the expression fields; this is a preference though, and you can define them if you wish.


## Magic field names

The system provides a set of core expression field names that will auto configure themselves so that you do not need to provide resource translations or configure the field through annotations in your handler.

### Boolean fields

These magic fields will always evaluate to `true` or `false` but show different labels in the expression builder depending on the name of the field (as shown below). End users can between states of these fields just by clicking on them within the condition builder.

* `_is`: "is" or "is not"
* `_has`: "has" or "has not" (refers to has/has not performed some action)
* `_posesses`: "has" or "does not have"
* `_did`: "did" or "did not" (e.g. do some action)
* `_was`: "was" or "was not"
* `_are`: "are" or "are not"
* `_will`: "will" or "will not"
* `_ever`: "ever" or "never"
* `_all`: "all" or "any"

### Operator fields

These special fields provide the user with a way to configure an operator that may relate to another field. i.e. "more than" "5"

* `_stringOperator`: gives the user a list of different string comparisons to choose from (contains, equals, etc.)
* `_dateOperator`: gives the user a list of date comparisons to choose from
* `_numericOperator`: gives the user a list of number comparisons to choose from
* `_periodOperator`: gives the user a list of time period based numeric comparisons to choose from

To use these fields in your expressions, the core provides a helper service, [[api-rulesengineoperatorservice]], that can be injected into your handler and used to evaluate whether or not the combination of comparison operator and configured value is true or false:

```luceescript
/**
 * @expressionContexts user
 */
component {

    property name="emsUserQueriesService"      inject="emsUserQueriesService";
    property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

    private boolean function evaluateExpression(
          required numeric count
        ,          string  _numericOperator = "gt"
    ) {
        var userId       = payload.user.id ?: "";
        var bookingCount = 0;

        if ( userId.len() ) {
            bookingCount = emsUserQueriesService.getUserBookingCount( userId=userId ); 
        }

        // we can use the rulesEngineOperatorService to do comparison with
        // our value, configured limit and operator:
        return rulesEngineOperatorService.compareNumbers( bookingCount, arguments._numericOperator, arguments.count );
    }
}
```

### Date comparison fields

These fields all give the user a date range picker to configure the field and provide your expression at runtime with a `struct` potentially containing `from` and `to` date values (it could also be an empty `struct` or contain only one of the keys).

* `_time`: Gives a date range picker that can be configured for both future and past ranges
* `_pastTime`: Gives a date range picker that is limited to past time ranges
* `_futureTime`: Gives a date range picker that is limited to future time ranges

Example usage:

```luceescript
/**
 * Expression to evaluate a logged in user's spend on events
 * 
 * @expressionContexts user
 */
component {

    property name="emsUserQueriesService"      inject="emsUserQueriesService";
    property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

    /**
     * @eventType.fieldtype   object
     * @eventType.object      ems_event_type
     * @eventType.multiple    false
     *
     */
    private boolean function evaluateExpression(
          required numeric amount
        ,          string  _numericOperator = "gt"
        ,          string  eventType = ""
        ,          struct  _pastTime // our past time date range Magic field
    ) {
        var userId        = payload.user.id ?: "";
        var bookingAmount = 0;

        if ( userId.len() ) {
            bookingAmount = emsUserQueriesService.getTotalBookingAmountForUser(
                  userId       = userId
                , dateFrom     = _pastTime.from ?: "" // from may not exist
                , dateTo       = _pastTime.to   ?: "" // to may not exist
                , eventType    = eventType
            );
        }

        return rulesEngineOperatorService.compareNumbers( bookingAmount, arguments._numericOperator, arguments.amount );
    }

}
```