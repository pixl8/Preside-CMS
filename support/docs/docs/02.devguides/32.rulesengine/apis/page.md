---
id: rulesengineapis
title: Rules engine APIs for evaluating conditions and generating filters
---

## Rules engine APIs for evaluating conditions and generating filters

There are two main methods for evaluating conditions in your code:

[[rulesengineconditionservice-evaluatecondition||rulesEngineConditionService.evaluateCondition()]]
and
[[rulesenginewebrequestservice-evaluatecondition||rulesEngineWebRequestService.evaluateCondition()]]

The first method should be used for everything except conditions in a web request context. The second should be used exclusively for web request conditions.

### An example

Let's imagine we have a slide show slide object that allows you to configure picture, link, title, etc. for a slide in a slide show. It would be great if we could configure it to show only when the chosen _condition_ is true (e.g. only show the promo for our Conference if you have not already booked on it). Our Preside Object might look like this:

```luceescript
component {
    // ...
    property name="condition" relationship="many-to-one" relatedTo="rules_engine_condition";
    // ...
}
```

The logic to then decide whether or not to show the slide:

```luceescript
// /handlers/somehandler.cfc
component {
    property name="slidesService"                inject="slidesService";
    property name="rulesEngineWebRequestService" inject="rulesEngineWebRequestService"; 

    private string function slides() {
        var slides         = slidesService.getMySlides( ... );
        var renderedSlides = "";

        for( var slide in slides ) {
            // evaluate the configured condition against the current web request
            if ( !Len( Trim( slide.condition ) ) || rulesEngineWebRequestService.evaluateCondition( slide.condition ) ) {
                renderedSlides &= renderView( view="/slides/_slide", args=slide );
            }
        }

        return renderedSlides;
    }
}
```