---
id: rulesengineexpressions
title: Creating a rules engine expression
---

## Summary

Rules engine expressions are a combination of an i18n resource file (`.properties` file) and a convention based handler that implements an `evaluateExpression` action and, optionally, a `prepareFilters` action should the expression be available for building filters.

>>> An expression can be scaffolded using the dev console `new ruleexpression` command


## i18n resource file

By convention, expression resource files must live at: `/i18n/rules/expressions/{idOfExpression}.properties`. This file must, at a minimum, declare two keys, `label` and `text`:

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

>>> Note the `{_has}` field. Chances are, if a field starts with an underscore, `_`, it is a "magic" system field that is automatically configured for you. See "Magic field names", in [[rulesenginefieldtypes]].

## The evaluateExpression handler action

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

### Expression context

The handler CFC file can be annotated with an `expressionContexts` attribute that will define in what contexts the expression can be used.

### Arguments passed to the evaluateExpression method

Because it is a ColdBox handler action, the method will always receive `event`, `rc` and `prc` arguments for you to use when relevant. In addition, the method will also always receive a `payload` argument that is a structure containing data relevant to the _context_ in which the expression is being evaluated. For example, the **webrequest** context provides a payload with `page` and `user` keys, each with a structure containing details of the current page and logged in user, respectively.

Any further arguments are treated as **expression fields** and should map to the `{placeholder}` fields defined in your expression resource file's `text` key. These arguments can also be decorated to configure the field further. For example, you may wish to define the field type + any further arguments that the field type requires:

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

>>>>>> We prefer to leave the `event`, `rc`, `prc` and `payload` arguments out of the function definition to show the expression fields more cleanly; this is a preference though, and you can define them if you wish.

## The prepareFilters handler action

The `prepareFilters()` handler action accepts the same dynamic arguments based on the configured expression as the `evaluateExpression()` action. However, instead of returning a boolean result, the method must return an array of **preside data object filters**. A simplistic example:

```luceescript
component {

    // ...
    /**
     * @objects event_session
     *
     */
    private boolean function prepareFilters(
          required string eventId       // arguments from configured expression 
        , required string objectName    // always passed to prepareFilters()
        , required string filterPrefix  // always passed to prepareFilters()
    ) {
        var paramName   = "eventId" & CreateUUId();  // important to avoid clashing SQL param names
        var fieldPrefix = arguments.filterPrefix.len() ? arguments.filterPrefix : arguments.objectName;

        return [ {
            filter       = "#fieldPrefix#.event = :#paramName#"
            filterParams = { "#paramName#" = arguments.eventId }
        } ];
    }

}

```

### Annotations

The `prepareFilters()` method expects an `objects` annotation that is a comma separated list of objects that the filter can apply to. You may have some common fields across different objects that require a custom expression, specifying multiple objects will make this possible. e.g.

```luceescript
/**
 * @expressionContexts page,event,profile,article
 */
component {

    private boolean function evaluateExpression() {
        // ...
    }

    /**
     * @objects page,event,profile,article
     *
     */
    private array function prepareFilters() {
        // ...
    }    
}

```

Notice how the `@expressionContexts` for the CFC is also likely to be the same list of objects.

### Arguments

Your `prepareFilters()` method will _always_ receive `objectName` and `filterPrefix` arguments. 

`objectName` is the name of the object being filtered. 

`filterPrefix` is a calculated prefix that should be put in front of any fields on the object that you use in filters. If the prefix is empty, then we are filtering _directly_ on the object (you may then wish to use the object name as a prefix as we have done in the example above). This is to allow filters to be nested and to be able to be buried deep in a traversal of the database entity relationships.

Any other arguments will by dynamically generated based on the expression's `evaluateExpression` definition and the user configured expression fields.

### A complex filter example

A rules engine filter can get a little complicated quite easily. For example, we may need to join on subqueries to be able to use some kind of statistical filter in conjunction with other dynamically generated filters. What follows is a more realistic example. Here we are filtering on whether or not website users have cancelled their place on a specific event:

```luceescript
component {

    // ...

    /**
     * @objects website_user
     */
    private boolean function prepareFilters(
          required string  eventId       // arguments from configured expression 
        , required boolean _has          // arguments from configured expression 
        , required string  objectName    // always passed to prepareFilters()
        , required string  filterPrefix  // always passed to prepareFilters()
    ) {
        // setup params and filter clause for the passed eventId
        var paramName     = "eventId" & CreateUUId();
        var params        = { "#paramName#"={ value=arguments.eventId, type="cf_sql_varchar" } };
        var subQueryAlias = "eventCancellations" & CreateUUId();
        var filterSql     = "#subQueryAlias#.cancellation_count #( arguments._has ? '>' : '=' )# 0";
        var fieldPrefix   = arguments.filterPrefix.len() ? arguments.filterPrefix : arguments.objectName;

        // generate a subquery with user ID and cancellation count
        // fields filtered by the passed eventID.
        // notice the 'getSqlAndParamsOnly' argument (added in 10.8.0)
        var subQuery = eventCancellationDao.selectData(
              getSqlAndParamsOnly = true
            , selectFields        = [ "Count( id ) as cancellation_count", "website_user as id" ]
            , groupBy             = "website_user"
            , filter              = "event = :#paramName#"
            , filterParams        = params
        );

        // return a preside object data filter that includes 'extraJoins'
        // array to allow us to join on our subquery
        return [ { filter=filterSql, filterParams=params, extraJoins=[ {
              type           = "left"
            , subQuery       = subQuery.sql
            , subQueryAlias  = subQueryAlias
            , subQueryColumn = "id"
            , joinToTable    = fieldPrefix
            , joinToColumn   = "id"
        } ] } ];

    }

}

```
