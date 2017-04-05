---
id: rulesengineapis
title: Rules engine APIs for evaluating conditions and generating filters
---

## Rules engine APIs for evaluating conditions and generating filters

### Evaluating conditions

The [[rulesengineconditionservice-evaluatecondition||rulesEngineConditionService.evaluateCondition()]] method allows you to evaluate a saved condition at runtime.

For example, let's imagine that we have a `slideshow_slide` object that allows you to configure `picture`, `link`, `title`, etc. for a slide in a slide show. It would be great if we could configure it to show only when the chosen _condition_ is true (e.g. only show the promo for our Conference if you have not already booked on it). Our Preside Object might look like this:

```luceescript
// slideshow_slide.cfc
component {
    // ...

    // ruleContext below tells the auto generated condition picker
    // formcontrol to limit conditions to "webrequest" compatible conditions
    property name="condition" relationship="many-to-one" relatedTo="rules_engine_condition" ruleContext="webrequest";
    // ...
}
```

The logic to then decide whether or not to show the slide:

```luceescript
// /handlers/somehandler.cfc
component {
    property name="slidesService"                inject="slidesService";
    property name="rulesEngineConditionService" inject="rulesEngineConditionService"; 

    private string function slides() {
        var slides         = slidesService.getMySlides( ... );
        var renderedSlides = "";

        for( var slide in slides ) {
            // show the slide if it has no condition, or the condition evaluates
            // to true. notice the "webrequest" context that matches the conditions
            // that we are allowed to choose (see object definition, above)
            var showSlide = !Len( Trim( slide.condition ) ) || rulesEngineConditionService.evaluateCondition( 
                  conditionId = slide.condition
                , context     = "webrequest" 
            );
            if ( showSlide ) {
                renderedSlides &= renderView( view="/slides/_slide", args=slide );
            }
        }

        return renderedSlides;
    }
}
```