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
    property name="slidesService"               inject="slidesService";
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

>>> The default form control for properties that relate to `rules_engine_condition` and that define a `ruleContext` is [[formcontrol-conditionpicker]]. You can also use this control and its options directly in your form definitions if you so need.

### Using saved filters

You can use saved filters in your everyday code to enhance the user experience and flexibility of your systems. Given a saved filter ID (from the `rules_engine_condition` object), you can use the [[rulesenginefilterservice-preparefilter|RulesEngineFilterService.prepareFilter()]] method to get an `extraFilters` filter array to pass to your `selectData()` call.

A useful example of this is a "Latest news" widget that allows you to choose a dynamic filter with which to filter the news to show. The widget form could look like this (see [[formcontrol-filterpicker]] for documentation on the filter picker):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<form i18nBaseUri="widgets.latestnews:">
    <tab id="default" sortorder="10">
        <fieldset id="default" sortorder="10">
            <field name="title"  control="textinput" />
            <field name="filter" control="filterpicker" filterobject="news" />
        </fieldset>
    </tab>
</form>
```

The service logic to use the saved filter might then look like this:

```luceescript
// /services/NewsService.cfc
component {
   
    // ...

    public query function getLatestNews( string filter="" ) {
        var extraFilters = [];

        if ( arguments.filter.len() ) {
            extraFilters.append( rulesEngineFilterService.prepareFilter(
                  objectName = "news"
                , filterId   = arguments.filter
            ) );
        }

        return newsDao.selectData(
              filter       = { published = true }
            , extraFilters = extraFilters
            , orderby      = "publish_date desc"
        );
    }

    // ...

}
```

If you are persisting a filter choice to the database (as opposed to just using in a widget), create a property with a relationship to the `rules_engine_condition` object. e.g.

```luceescript
// /preside-objects/my_object.cfc
component {
    
    // ...

    property name="required_filter"  relationship="many-to-one"  relatedto="rules_engine_condition" control="filterpicker" filterobject="my_object";
    property name="optional_filters" relationship="many-to-many" relatedto="rules_engine_condition" relatedvia="my_object_optional_filter" control="filterpicker" filterobject="my_object" multiple=true;

    // ...

}
```