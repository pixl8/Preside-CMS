# Rules Engine: Conditions, Filters & Expressions

## Concepts

| Term | Description |
|------|-------------|
| **Expression** | A single evaluatable item — returns true/false |
| **Condition** | User-configured combination of expressions (AND/OR) for access/display logic |
| **Filter** | Like a condition but tied to a single Preside Object — produces a database filter |
| **Context** | The evaluation environment (webrequest, page, user, etc.) |
| **Field Type** | UI control for expression configuration parameters |

---

## Contexts

Contexts define what data is available when evaluating expressions.

### Configuration

```cfml
// Config.cfc
settings.rulesEngine.contexts.webrequest = {
    subcontexts = [ "user", "page" ]  // These contexts' payload is merged in
};
settings.rulesEngine.contexts.page = {
    object = "page"   // Object whose records can be used in filter building
};
settings.rulesEngine.contexts.user = {
    object = "website_user"
};
```

### i18n

```properties
# /i18n/rules/contexts.properties
webrequest.title=Web request
webrequest.description=Conditions for a web page request
webrequest.iconClass=fa-globe

page.title=Web page
page.description=Conditions for a site tree page
page.iconClass=fa-file-o

user.title=Website user
user.description=Conditions about the current user
user.iconClass=fa-user
```

### Context Payload Handler

Provides the data available to expressions during evaluation:

```cfml
// /handlers/rules/contexts/User.cfc
component {
    private struct function getPayload() {
        return {
            user = {
                  id    = isWebsiteUserLoggedIn() ? getLoggedInWebsiteUserId() : ""
                , email = isWebsiteUserLoggedIn() ? getLoggedInWebsiteUserDetails().email_address : ""
            }
        };
    }
}
```

---

## Expressions

### Simple Boolean Expression

```cfml
// /handlers/rules/expressions/UserIsLoggedIn.cfc
/**
 * @expressionContexts webrequest
 */
component {

    // _is is a magic boolean field — true = "is", false = "is not"
    private boolean function evaluateExpression( boolean _is=true ) {
        return arguments._is == isWebsiteUserLoggedIn();
    }
}
```

```properties
# /i18n/rules/expressions/userIsLoggedIn.properties
label=User is logged in
text=User {_is} logged in
```

### Expression With Fields

```cfml
// /handlers/rules/expressions/UserHasBookedEvent.cfc
/**
 * @expressionContexts webrequest,user
 */
component {

    property name="bookingService" inject="bookingService";

    /**
     * @emsEvent.fieldType object
     * @emsEvent.object    event
     * @emsEvent.multiple  false
     */
    private boolean function evaluateExpression(
          required string  emsEvent
        ,          boolean _has = true
    ) {
        var userId = payload.user.id ?: "";

        if ( !Len(userId) || !Len(arguments.emsEvent) ) {
            return !arguments._has;
        }

        var hasBooked = bookingService.userHasBooked(
              userId  = userId
            , eventId = arguments.emsEvent
        );
        return hasBooked == arguments._has;
    }
}
```

```properties
# /i18n/rules/expressions/userHasBookedEvent.properties
label=User has booked an event
text=User {_has} booked {emsEvent}
```

### Expression With Operators

```cfml
// /handlers/rules/expressions/UserBookingCount.cfc
/**
 * @expressionContexts user
 */
component {

    property name="bookingService"              inject="bookingService";
    property name="rulesEngineOperatorService"  inject="rulesEngineOperatorService";

    /**
     * @count.fieldType number
     */
    private boolean function evaluateExpression(
          required numeric count
        ,          string  _numericOperator = "gt"
    ) {
        var bookingCount = bookingService.getUserBookingCount( payload.user.id ?: "" );
        return rulesEngineOperatorService.compareNumbers(
              bookingCount
            , arguments._numericOperator
            , arguments.count
        );
    }
}
```

---

## Magic Field Types

Parameters with special names get special UI treatment automatically:

| Parameter Name | Behaviour |
|----------------|-----------|
| `_is` | Boolean toggle: "is" / "is not" |
| `_has`, `_possesses`, `_did`, `_was`, `_are`, `_will`, `_ever`, `_all` | Boolean variants |
| `_stringOperator` | String comparison dropdown (equals, contains, startsWith, etc.) |
| `_numericOperator` | Numeric comparison dropdown (gt, gte, lt, lte, eq, neq) |
| `_dateOperator` | Date comparison dropdown |
| `_periodOperator` | Period comparison |
| `_time` | Date/time range picker (past or future) |
| `_pastTime` | Past time range picker |
| `_futureTime` | Future time range picker |

---

## Filter Expressions (for DB filtering)

Filter expressions produce database filters (SQL) rather than returning a boolean.

```cfml
// /handlers/rules/expressions/UserHasBookedEventFilter.cfc
/**
 * @expressionContexts user
 */
component {

    property name="bookingDao" inject="presidecms:object:booking";

    /**
     * @objects website_user
     */
    private array function prepareFilters(
          required string  emsEvent
        ,          boolean _has = true
        , required string  objectName
        ,          string  filterPrefix = ""
    ) {
        var paramName       = "event_#CreateUUId()#";
        var subQueryAlias   = "bookings_#CreateUUId()#";
        var filterParams    = { "#paramName#" = { value=arguments.emsEvent, type="cf_sql_varchar" } };
        var filterSql       = "#subQueryAlias#.booking_count #arguments._has ? '>' : '='# 0";

        var subQuery = bookingDao.selectData(
              getSqlAndParamsOnly = true
            , selectFields        = [ "Count(id) as booking_count", "website_user as id" ]
            , groupBy             = "website_user"
            , filter              = "event = :#paramName#"
            , filterParams        = filterParams
        );

        return [{
              filter      = filterSql
            , filterParams = filterParams
            , extraJoins  = [{
                  type            = "left"
                , subQuery        = subQuery.sql
                , subQueryAlias   = subQueryAlias
                , subQueryColumn  = "id"
                , joinToTable     = arguments.objectName
                , joinToColumn    = "id"
              }]
        }];
    }
}
```

---

## Using Conditions in Code

### Evaluate a condition (true/false check)

```cfml
property name="rulesEngineConditionService" inject="rulesEngineConditionService";

function shouldShowWidget( required string conditionId ) {
    if ( !Len( Trim( arguments.conditionId ) ) ) { return true; }

    return rulesEngineConditionService.evaluateCondition(
          conditionId = arguments.conditionId
        , context     = "webrequest"
    );
}
```

In a view:
```cfm
<cfif not Len( args.visibility_condition ) or rulesEngineConditionService.evaluateCondition( conditionId=args.visibility_condition, context="webrequest" )>
    <!-- Show this content -->
</cfif>
```

### Use a filter (database filtering)

```cfml
property name="rulesEngineFilterService" inject="rulesEngineFilterService";

function getFilteredUsers( required string filterId ) {
    var extraFilters = [];

    if ( Len( Trim( arguments.filterId ) ) ) {
        extraFilters.append(
            rulesEngineFilterService.prepareFilter(
                  objectName = "website_user"
                , filterId   = arguments.filterId
            )
        );
    }

    return userDao.selectData(
          filter       = { active=true }
        , extraFilters = extraFilters
        , orderBy      = "display_name asc"
    );
}
```

---

## Auto-Generated Expressions

Preside can auto-generate basic filter expressions from object properties:

```cfml
// On the object:
/**
 * @autoGenerateFilterExpressionsFor website_user.email
 */
component {
    property name="email" autofilter=true;  // Included in auto-generation
    property name="notes" autofilter=false; // Excluded
}

// On a many-to-many property:
property name="categories" relationship="many-to-many" relatedTo="category"
    autoGenerateFilterExpressions=true;
```

Customize auto-generated expression labels:
```properties
# /i18n/preside-objects/blog_post.properties
field.categories.possesses.truthy=is tagged with
field.categories.possesses.falsey=is not tagged with
```

---

## Custom Field Types

```cfml
// /handlers/rules/fieldtypes/MyPicker.cfc
component {

    private string function renderConfiguredField( string value="", struct config={} ) {
        // Render the configured value as human-readable text
        if ( !Len( Trim( arguments.value ) ) ) {
            return translateResource( "rules.fieldtypes.MyPicker:not.set" );
        }
        return getModel("myService").getLabelForId( arguments.value );
    }

    private string function renderConfigScreen( string value="", struct config={} ) {
        // Render the configuration UI (form control)
        return renderFormControl(
              name        = "value"
            , type        = "objectPicker"
            , object      = "my_object"
            , label       = translateResource( config.fieldLabel ?: "rules.fieldtypes.MyPicker:config.label" )
            , savedValue  = arguments.value
            , required    = true
        );
    }

    // Optional: transform value into data usable by evaluateExpression()
    private any function prepareConfiguredFieldData( string value="", struct config={} ) {
        return getModel("myService").getDataForId( arguments.value );
    }
}
```

Register custom field type:
```cfml
// Config.cfc
settings.rulesEngine.fieldTypes.myPicker = {
    handler = "rules.fieldtypes.MyPicker"
};
```

---

## Condition Picker in Forms

To let editors pick conditions/filters in forms:

```xml
<!-- Condition picker (true/false evaluation) -->
<field name="visibility_condition"
       control="conditionpicker"
       context="webrequest"
       label="Visibility Condition" />

<!-- Filter picker (for data filtering) -->
<field name="audience_filter"
       control="filterpicker"
       object="website_user"
       label="Audience Filter" />
```
