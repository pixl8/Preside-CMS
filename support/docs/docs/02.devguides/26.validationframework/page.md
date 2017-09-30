---
id: validation-framework
title: Validation framework
---

The PresideCMS platform provides its own validation framework. This framework is used in the forms system without the need of any specific knowledge of its working. However, you may find yourself requiring custom validation and wanting to use the framework directly. The guide below provides a comprehensive reference for the framework's APIs.

# Core concepts

There are four core concepts to the API:

1. **Rules**: A _rule_ is a constraint on a given field - e.g. "password must be longer than 15 characters".

2. **Rulesets**: A _ruleset_ is a collection of rules.

3. **Validators**: A _Validator_, is a _named process_ that takes the submitted data and returns an indication of whether or not the data is valid. For example, `isValidEmail`, `minValue`, `required`, etc. The API supplies a set of core validators that can be easily supplemented and overriden with your own custom validators. Every _rule_ must have a _single validator_.

4. **Validation providers**: A `Validator Provider` is a CFC file that provides a collection of _validators_ (public methods).

![Overview of the Validation system](images/diagrams/validation-engine-overview.jpg)

# Working with the API

The core validation API is used by Preside when rendering and processing forms. It does this under-the-hood so that, in general, you do not need to deal with it directly. An exception to this might occur should you wish to do some custom code that will not use the Preside Abstractions.The API has four core methods that allow you to:

* Register custom validator providers
* Register rulesets
* Validate some data against a ruleset
* Produce client-side validation code for a given ruleset

See [[api-validationengine]] for API docs.

## Examples

The following code samples show working with the API directly. This is rough code and is intended to illustrate the shape of using the API.

```luceescript

// registering some custom validators through a validation provider
validationEngine.newProvider( getModel( "cfcWithCustomValidatorMethods" ) );

// long hand way of defining a ruleset (can be provided as json, file containing json or array of structs)
var ruleset = [];

ruleset.append( { fieldName="emailAddress"   , validator="required" } );
ruleset.append( { fieldName="emailAddress"   , validator="email"    } );
ruleset.append( { fieldName="password"       , validator="required" } );
ruleset.append( { fieldName="confirmPassword", validator="required" } );
ruleset.append( { fieldName="password"       , validator="minLength", params={ length = 6          } } );
ruleset.append( { fieldName="confirmPassword", validator="sameas"   , params={ field  = "password" } } );

validationEngine.newRuleset( "myCustomFormRules", ruleset );

// validating a form submission
var validationResult = validationEngine.validate( "myCustomFormRules", form );
if ( validationResult.validated() ) {
    // ...
} else {
    // ...
}
```

```lucee
<!-- HTML and client side validation -->
<cfoutput>
    <form id="myCustomForm" method="post" action="#urlToProcessFormSubmission#">

        <!-- outputting an error message for a field -->
        <cfif validationResult.fieldHasError( "emailAddress" )>
            <p class="error-message">#validationResult.getError( "emailAddress" )#</p>
        </cfif>

    </form>

    <!-- generating js for client side validation -->
    <script type="text/javascript">
        ( function( $ ){
            var validateOptions = #validationEngine.getJqueryValidateJs( "myCustomFormRules", "jQuery" )#;
            $( '##myCustomForm' ).validate( validateOptions );
        } )( jQuery );
    </script>
</cfoutput>
```

# Rules and Rulesets

## Rules

A rule defines a constraint for a named field. e.g. the field named "username" must be longer than three characters. A single rule can be made up of the following attributes:

* **fieldName (required):** The name of the field to which the rule applies
* **validator (required):** The name of the validator with which to validate the field, i.e. "minLength"
* **params (optional):** Optional structure of parameters to send to the validator. i.e. the minLength validator requires a "length" parameter
*message (optional):* Optional message to display should the rule be broken. This will default to the default message associated with the validator.
* **serverCondition (optional):** CFML to evaluate whether or not the rule should be run, e.g. only run the "required" rule for "retypeNewPassword" when "oldPassword" and "newPassword" have been filled in
* **clientCondition (optional):** JavaScript for conditionally running rules client-side (in produced javascript)

### Examples

```luceescript
// required field
{
      fieldName : "username"
    , validator : "required"
    , message   : "Username is required"
}

// field should be between 3 and 10 characters long
{
      fieldName : "username"
    , validator : "rangeLength"
    , params    : { minLength : 3, maxLength : 10 }
}

// field is only required when the "Where did you hear" field is equal to "other"
{
      fieldName : "whereDidYouHearOther"
    , validator : "required"
    , serverCondition : "${whereDidYouHear} eq 'other'"
    , clientCondition : "${whereDidYouHear}.val() === 'other'"
}
```

### Conditional rules, referencing other fields

As shown above, conditional rules allow you to conditionally run a rule based on just about any logic you can think of. For ease and information hiding, the API provides the `${fieldname}` syntax for accessing other fields in the form / dataset.

For server side validation, the macro will evaluate to the _value_ of the field, i.e. `${password}` will be translated to something like: `arguments.data[ 'password' ]`.

In client-side validation, the macro will evaluate to the jQuery object for the form field, i.e. `${username}` will be translated to something like `$( elementBeingValidated ).nearest( 'form' ).find( '[name="username"]' )`.

## Registering rulesets to the engine

A ruleset is an array of rules that are registered, with a unique name, to the core validation engine using the `newRuleset()` method. The set of rules for the ruleset can be defined in three ways:

1. As a CFML array of structures (each structure containing the rule attributes described above)
2. As a JSON string that evaluates to an array of structs
3. As a file path pointing to a file that contains a JSON string that evaluates to CFML array of structs

### Examples

```luceescript
// register a ruleset with the name "myRuleset", using an array of structs
ruleset = validationEngine.newRuleset( "myRuleset", [{fieldName="username", validator="required"}, {fieldName="password", validator="required" }] );

// register a ruleset with the name "myRuleset", using a json string
ruleset = validationEngine.newRuleset( "myRuleset", '[{"fieldName":"username", "validator":"required"}, {"fieldName":"password", "validator":"required" }]' );

// register a ruleset with the name "myRuleset", using a filepath
ruleset = validationEngine.newRuleset( "myRuleset", ExpandPath( "/myrulesets/myruleset.json" ) );
```

## Custom validators and validator providers

Custom validators can be passed to the engine by passing an _instantiated_ CFC that contains public _validator methods_. For example, you might have:

```luceescript
myValidatorCfc = getModel( "someComponentThatHasValidatorMethods" );

validationEngine.newProvider( myValidatorCfc );
```

The _public_ methods in a component can be marked as being _validators_. The name of the method will be the name of the registered _validator_. A component can provide validator methods in two ways:

1. By adding the `validationProvider="true"` attribute to the component tag, all public methods will then be considered validators
2. By adding the `validator="true"` attribute to the function tag of the method that should be a validator

Default error messages can be provided for a validator method by adding the `validatorMessage="some message"` attribute to the function tag.

### Format of a validator method

Any method that is registered as a validator should return a boolean value. By returning `true`, the method is asserting that the provided data was valid.

The method will always be given the following three arguments:

* **fieldName:** The name of the field being validated
* **value:** The value of the field being validated
* **data:** The entire data structure that is being validated

Additionally, you can define your own custom arguments that will need to be defined in the `params` attribute of any rules that use your validator.

Example method:

```luceescript
/**
 * @validator
 * @validatorMessage This is not a slug (or a snail)
 */
public boolean function slug(
      required string  fieldName
    , required any     value
    , required struct  data
    , required boolean allowMixedCase // custom argument
) {
    var aToZ = arguments.allowMixedCase ? "a-zA-Z" : "a-z";

    // if empty input, do not perform custom validation
    if ( !IsSimpleValue( arguments.value ) || !Len( Trim( arguments.value ) ) ) {
        return true;
    }

    return ReFind( "^[#aToZ#0-9\-]+$", arguments.value );
}

// ...

// usage in a rule
ruleset.append( { fieldName="eventSlug", validator="slug", params={ allowMixedCase = true } } );
```

### Providing client side logic for custom validators

The API allows you to define javascript logic for your custom validators. This logic will be used when creating the javascript for a given ruleset when rendering a form. The javascript itself must be any valid javascript that could be provided as a custom validator to the jQuery Validate plugin.

To define the javascript in your provider, simply create a method with the same name as your validator but with "_js" appended. The method should return a string containing the javascript. For the slug example, above, the js validator method could look like this:

```luceescript
public boolean function slug_js() {
    return "function( value, elem, params ){
                var regex = params.allowMixedCase ? /^[a-zA-Z0-9\-]+$/ : /^[a-z0-9\-]+$/;
                return !value.length || value.match( regex ) !== null;
            }"
}
```

### Example provider CFCs

```luceescript
/**
 * All public methods in this CFC will be assumed
 * to be validators because I am tagged with @validationProvider
 *
 * @validationProvider
 */
component {

    /**
     * @validatorMessage customvalidators:slug.message
     */
    public boolean function slug(
          required string  fieldName
        , required any     value
        , required struct  data
        , required boolean allowMixedCase // custom argument
    ) {
        var aToZ = arguments.allowMixedCase ? "a-zA-Z" : "a-z";

        // if empty input, do not perform custom validation
        if ( !IsSimpleValue( arguments.value ) || !Len( Trim( arguments.value ) ) ) {
            return true;
        }

        return ReFind( "^[#aToZ#0-9\-]+$", arguments.value );
    }

    public boolean function slug_js() {
        return "function( value, elem, params ){
                    var regex = params.allowMixedCase ? /^[a-zA-Z0-9\-]+$/ : /^[a-z0-9\-]+$/;
                    return !value.length || value.match( regex ) !== null;
                }"
    }
}
```

Any old CFC with ad-hoc validation methods:


```luceescript
component {

    /**
     * This is not a validator, as it is not
     * tagged with @validator (and the CFC is not
     * tagged with @validationProvider)
     *
     */
    public any function someFunction() {
        // do stuff
    }

    /**
     * A method that will be used as a validator
     * because tagged with @validator, below
     *
     * @validator
     * @validatorMessage customvalidators:slug.message
     */
    public boolean function membershipNumber(
          required string  fieldName
        , required any     value
    ) {
        if ( !Len( Trim( arguments.value ) ) ) {
            return true;
        }

        return ReFind( "^M[0-9]{8}$", arguments.value );
    }

    /**
     * js version of the membershipNumber validator method
     * note: we do not need to flag this with @validator
     *
     */
    public boolean function membershipNumber_js() {
        return "function( value ){ return !value.length || value.match( /^M[0-9]{8}$/ ) !== null; }";
    }
}
```

## Server-side validation

Once you have your rulesets and any custom validators registered, validating a set of data (structure) is as straight forward as:

```luceescript
result = validationEngine.validate( "nameOfRuleset", data );
if ( result.validated() ) {
    // ... proceed
}
```

As you might gather from the code above, the `validate()` method returns a [[api-validationresult]] object (see API docs for its method signatures).

## Client-side validation

The `getJqueryValidateJs( ruleset, jqueryReference )` method, will return JavaScript to build all the required options for the jQuery Validate plugin. The javascript itself is an executed anonymous function that registers any custom validators with jQuery Validate and then returns an object that can be passed to the validate() method. An example of the produced js (with added comments), could look like this:

```js
( function( $ ){
    // translateResource() for i18n w/ error messages
    var translateResource = ( i18n && i18n.translateResource ) ? i18n.translateResource : function(a){ return a };

    // register custom validators
    $.validator.addMethod( "validator1", function( value, element, params ){ return false; }, "" );
    $.validator.addMethod( "validator2", function( value, element, params ){ return true; }, "" );

    // return the options to be passed to validate()
    return {
        rules : {
            "field1" : {
                "required" : { param : [] },
                "validator1" : { param : [], depends : function( el ){ return $( this.form ).find( "[name=''field1'']" ).val() === "whatever"; } }
            },
            "field2" : {
                "validator2" : { param : [ "test", false ] }
            }
        },
        messages : {
            "field1" : {
                "required" : translateResource( "Not there", { data : [] } ),
                "validator1" : translateResource( "validation:another.message.key", { data : [] } )
            },
            "field2" : {
                "validator2" : translateResource( "validation:some.error.key", { data : [ true ] } )
            }
        }
    };
} )( jQuery )
```

An example usage of the generated javascript might then look like:

```js
( function( $ ){
    // auto generate the rules and messages for validate()
    var validateOptions = #validationEngine.getJQueryValidateJs( "myRuleset", "jQuery" )#;

    // add any other options you need
    validateOptions.debug = true;
    validateOptions.submitHandler = myCustomSubmitHandler;

    // apply to the form
    $( '##myFormId' ).validate( validateOptions );
} )( jQuery );
```

## i18n

The validation API does not take any responsibility for i18n. If you wish to have translatable error messages, simply provide the resource bundle key of the message (see the core Preside i18n page for more details on resource bundles, etc.). For example:

```luceescript
// non-i18n version
ruleset.append( { fieldName="username", validator="minLength", message="Username must be less than 3 characters", params={length=3} } );

// i18n version
ruleset.append({ fieldName="username", validator="minLength", message="validationMessages:myform.username.minLength", params={length=3} } );
```

The generated client side code will automatically try to translate the message using the core Preside i18n functionality. To manually translate the message server-side, you would do:

```lucee
<p class="error-message">
    #translateResource(
          uri          = validationResult.getError( "myField" )
        , defaultValue = validationResult.getError( "myField" )
        , data         = validationResult.listErrorParameterValues( "myField" )
    )#
</p>
```

### Dynamic parameters for translations

Translatable texts often require dynamic variables. An example validation message requiring dynamic values might be: `"Must be at least {1} characters"`. Depending on the configured minimum character count, the message would substitue `"{1}"` for the minimum length.

For this to work, the method that translates the message must accept an array of dynamic parameters. These parameters can be retrieved using the `listErrorParameterValues( fieldName )` method of the [[api-validationresult]] object (see the example, above). The parameters themselves will be any custom parameters defined in your validator, **in the order that they are defined in the validator method**. For example:

```luceescript
// validator definition
public boolean function rangeLength(
    required string  fieldName // core
    required string  value     // core
    required struct  data      // core
    required numeric minLength // custom
    required numeric maxLength // custom
) {
    var length = Len( Trim( arguments.value ) );

    return !length || ( length >= arguments.minLength && length <= arguments.maxLength );
}

// ...

// rule definition
ruleset.append( { fieldName="someField", validator="rangeLength", params={ minLength=10, maxLength=200 } } );

// validation result error message generation
var errorMessage    = validationResult.getError( "someField" ); // e.g. validationmessages:rangelength.message
var parameterValues = validationResult.listErrorParameterValues( "someField" ); // [ 10, 200 ]

errorMessage = translateResource(
      uri          = errorMessage
    , defaultValue = errorMessage
    , data         = parameterValues
);

// if the resource bundle message for 'validationmessages:rangelength.message'
// was: "Must be between {1} and {2} characters long", then errorMessage would
// be "Must be between 10 and 200 characters long"

```