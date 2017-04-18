---
id: rulesenginefieldtypes
title: Rules engine field types
---

## Summary

Field types provide different UIs and option sets for configurable fields in rules engine expressions (see [[rulesengine]] for a higher level overview of the rules engine).

## System field types

The system comes with several built in expression field types. These may be automatically configured based on your expression handlers argument _type_ or they may need strict configuration. See the documentation for each for further details:

* `Asset`: TODO
* `Boolean`: TODO
* `Condition`: TODO
* `Date`: TODO
* `Number`: TODO
* `Object`: TODO
* `Operator`: TODO
* `Page`: TODO
* `PageType`: TODO
* `Select`: TODO
* `Text`: TODO
* `TimePeriod`: TODO
* `WebsiteUserAction`: TODO

## Creating custom field types

New field types can be created for your expressions. They are defined by creating a ColdBox handler at `/handlers/rules/fieldtypes/{idOfFieldType}.cfc`, that the following actions:

* `renderConfiguredField()` (required) should return a string that is a rendered representation of the configured field. This will appear in the condition builder
* `renderConfigScreen()` (required) should return a string with a render configuration screen (just the innards of a form). The most simple implementation is to render a form with a single field named 'value'. If you do so, the system will take care of the rest
* `prepareConfiguredFieldData()` (optional) Allows you to prepare a configured value at runtime before it is passed to the `evaluateExpression()` method of an expression. The raw value from the config form will be used by default if this method is not provided.

Here is the handler for our most complex field type, the `TimePeriod` type:

```luceescript
// /handlers/rules/fieldtypes/TimePeriod.cfc
component {

    property name="presideObjectService" inject="presideObjectService";
    property name="timePeriodService"    inject="rulesEngineTimePeriodService";

    private string function renderConfiguredField( string value="", struct config={} ) {
        var timePeriod = {};
        var data       = [];
        var type       = "alltime";

        try {
            timePeriod = DeserializeJson( arguments.value );
        } catch( any e ){
            timePeriod = { type="alltime" };
        };

        switch( timePeriod.type ?: "alltime" ){
            case "between":
                type = timePeriod.type;
                data = [ timePeriod.date1 ?: "", timePeriod.date2 ?: "" ];
            break;
            case "since":
            case "before":
            case "until":
            case "after":
                type = timePeriod.type;
                data = [ timePeriod.date1 ?: "" ];
            break;
            case "recent":
            case "upcoming":
                type = timePeriod.type;
                data = [
                      NumberFormat( Val( timePeriod.measure ?: "" ) )
                    , translateResource( "cms:time.period.unit.#( timePeriod.unit ?: 'd' )#" )
                ];
            break;
            default:
                type = "alltime";
        }

        return translateResource( uri="cms:rulesEngine.time.period.type.#type#.configured", data=data );
    }

    private string function renderConfigScreen( string value="", struct config={} ) {
        return renderFormControl(
              name         = "value"
            , type         = "timePeriodPicker"
            , pastOnly     = IsTrue( config.pastOnly   ?: "" )
            , futureOnly   = IsTrue( config.futureOnly ?: "" )
            , label        = translateResource( config.fieldLabel ?: "cms:rulesEngine.fieldtype.timePeriod.config.label" )
            , savedValue   = arguments.value
            , defaultValue = arguments.value
            , required     = true
        );
    }

    private struct function prepareConfiguredFieldData( string value="", struct config={} ) {
        return timePeriodService.convertTimePeriodToDateRange( arguments.value );
    }

}
```

## Magic field names

The system provides a set of core expression field names that will auto-configure themselves so that you do not need to provide resource translations or configure the field through annotations in your handler.

## Boolean fields

These magic fields will always evaluate to `true` or `false` but show different labels in the expression builder depending on the name of the field (as shown below). End users can between states of these fields just by clicking on them within the condition builder.

* `_is`: "is" or "is not"
* `_has`: "has" or "has not" (refers to has/has not performed some action)
* `_possesses`: "has" or "does not have"
* `_did`: "did" or "did not" (e.g. do some action)
* `_was`: "was" or "was not"
* `_are`: "are" or "are not"
* `_will`: "will" or "will not"
* `_ever`: "ever" or "never"
* `_all`: "all" or "any"

## Operator fields

These special fields provide the user with a way to configure an operator that may relate to another field. i.e. "more than" "5".

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

## Date comparison fields

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