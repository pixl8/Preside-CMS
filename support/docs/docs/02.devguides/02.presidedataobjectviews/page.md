---
id: presidedataobjectviews
title: Preside Data Object Views
---

## Overview

PresideCMS provides a feature that allows you to autowire your data model to your views, completely bypassing hand written handlers and service layer objects. Rendering one of these views looks like this:

```lucee
#renderView(
      view          = "events/preview"
    , presideObject = "event"
    , filter        = { event_category = rc.category }
)#
```

In the expample above, the `/views/events/preview.cfm` view will get rendered for each *event* record that matches the supplied filter, `{ event_category = rc.category }`. Each rendered view will be passed the database fields that it needs as individual arguments.

In order for the `renderView()` function to know what fields to select for your view, the view itself must declare what fields it requires. It does this using the `<cf_presideparam>` custom tag. Using our "event preview" example from above, our view file might look something like this:

```lucee
<cf_presideparam name="args.label"                                  /><!-- I need the 'label' field -->
<cf_presideparam name="args.teaser"                                 /><!-- I need the 'teaser' field -->
<cf_presideparam name="args.image"                                  /><!-- I need the 'image' field -->
<cf_presideparam name="args.event_type_id" field="event_type"       /><!-- I need the 'event_type' field, but aliased to 'event_type_id' -->
<cf_presideparam name="args.event_type"    field="event_type.label" /><!-- I need the 'label' field from the relatated object, event_type, aliased to 'event_type' -->

<cfparam name="_counter" type="numeric" /><!-- current row in the recordset being rendered -->
<cfparam name="_records" type="numeric" /><!-- total records in the recordset being rendered -->

<cfoutput>
    <div class="preview-pane">
        <h3>#args.label#</h3>
        <p class="event-type">
            <a href="#event.buildLink( pageId=args.event_type_id )#">
                #args.event_type#
            </a>
        </p>

        #renderAsset( assetId=args.image, context="previewPane" )#

        <p>#args.teaser#</p>
    </div>
</cfoutput>
```

>>> We introduced the `<cf_presideparam` custom tag in **PresideCMS 10.2.4**. Prior to this, we used the `<cfparam` tag for this feature. The 
`<cfparam` tag approach will continue to work in version 10 but we may decide to drop this support in future versions. This change is due to an unforeseen incompatibility with Adobe ColdFusion.

Given the examples above, the SQL you would expect to be automatically generated and executed for you would look something like this:

```sql
select     event.label
         , event.teaser
         , event.image
         , event.event_type as event_type_id
         , event_type.label as event_type

from       pobj_event      event
inner join pobj_event_type event_type on event_type.id = event.event_type

where      event.event_category = :event_category
```

## Filtering the records to display

Any arguments that you pass to the `renderView()` method will be passed on to the Preside Object `selectData()` method when retrieving the records to be rendered.

This means that you can specify any number of valid `selectData()` arguments to filter and sort the records for display. e.g.

```luceescript
rendered = renderView(
      view          = "event/detail"
    , presideObject = "event"
    , id            = eventId
);

rendered = renderView(
      view          = "event/preview"
    , presideObject = "event"
    , filter        = "event_type != :event_type or comment_count < :comment_count"
    , filterParams  = { event_type=rc.type, comment_count=10 }
    , startRow      = 11
    , maxRows       = 10
    , orderBy       = "datepublished desc"
);
```

## Declaring fields for your view

As seen in the examples above, the `<cf_presideparam>` tag is used by your view to specify what fields it needs to render. Any variable that is declared that starts with "args." will be considered a field on your preside object by default.

If we are rendering a view for a **news**  object, the following param will lead to `news.headline` being retrieved from the database:

```lucee
<cf_presideparam name="args.headline" />
```


### Aliases

You may find that you need to have a different variable name to the field that you need to select from the data object. To achieve this, you can use the `field` attribute to specify the name of the field:

```lucee
<cf_presideparam name="args.headline" field="news.label" />
```

You can use the same technique to do aggregate fields and any other SQL select goodness that you want:

```lucee
<cf_presideparam name="args.headline"      field="news.label" />
<cf_presideparam name="args.comment_count" field="Count( comments.id )" />
```

### Getting fields from other objects

For one to many style relationships, where your object is the many side, you can easily select fields from the related object using the `field` attribute shown above. Simply prefix the column name with the name of the foreign key field on your object. For example, if our **news** object has a single **news_category** field that is a foreign key to a category lookup, we could get the title of the category with:

```lucee
<cf_presideparam name="args.headline" field="news.label" />
<cf_presideparam name="args.category" field="news_category.label" />
```

### Front end editing

If you would like a field to be editable in the front end website, you can set the `editable` attribute to **true**:

```lucee
<cf_presideparam name="args.label" editable="true" />
```

### Accepting arguments that do not come from the database

Your view may need some variables that do not come from the database. For example, in the code below, the view is being passed the `showComments` argument that does not exist in the database.

```lucee
#renderView( view="myview", presideObject="news", args={ showComments=false } )#
```

To allow this to work, you can specify `field="false"`, so:

```lucee
<cf_presideparam name="args.headline" field="news.label" />
<cf_presideparam name="args.category" field="news_category.label" />
<cfparam name="args.showComments"     field="false" type="boolean" />
```

This looks as though it should not be necessary because we are using the `<cfparam` tag to state that we expect the `args.showComments` variable to be available. However, the `cfparam` tag is still supported here for backward compatibility with versions of PresideCMS prior to **10.2.4**. As an alternative approach, one can use something like:

```lucee
<cf_presideparam name="args.headline" field="news.label" />
<cf_presideparam name="args.category" field="news_category.label" />

<cfset showComments = IsTrue( args.showComments ?: "" ) />
```

### Defining renderers

Each of the fields fetch from the database for your view will be pre-rendered using the default renderer for that field. So fields that use a richeditor will have their Widgets and embedded assets all ready rendered for you. To specify a different renderer, or to specify renderers on calculated fields, do:

```lucee
<cf_presideparam name="args.comment_count" field="Count( comments.id )" renderer="myNumberFormatter" />
```

## Caching

You can opt to cache your preside data object views by passing in caching arguments to the [[presideobjectviewservice-renderView]] method. A minimal example:

```luceescript
rendered = renderView(
      view          = "event/detail"
    , presideObject = "event"
    , id            = eventId
    , cache         = true     // cache with sensible default settings
);
```

See the [[presideobjectviewservice-renderView]] method documentation for details on all the possible arguments.


