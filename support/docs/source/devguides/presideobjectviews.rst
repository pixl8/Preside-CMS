Preside Data Object Views
=========================

PresideCMS provides a feature that allows you to autowire your data model to your views, completely bypassing hand written handlers and service layer objects. Rendering one of these views looks like this:

.. code-block:: cfm

    #renderView(
          view          = "events/preview"
        , presideObject = "event"
        , filter        = { event_category = rc.category }
    )#

In the expample above, the :code:`/views/events/preview.cfm` view will get rendered for each *event* record that matches the supplied filter, :code:`{ event_category = rc.category }`. Each rendered view will be passed the database fields that it needs as individual arguments.

In order for the :code:`renderView()` function to know what fields to select for your view, the view itself must declare what fields it requires. It does this using the :code:`<cfparam>` tag. Using our "event preview" example from above, our view file might look something like this:

.. code-block:: cfm

    <cfparam name="args.label" /><!--- I need the 'label' field from the preside object --->
    <cfparam name="args.teaser" /><!--- I need the 'teaser' field --->
    <cfparam name="args.image"  /><!--- I need the 'image' field --->
    <cfparam name="args.event_type_id" field="event_type" /><!--- I need the 'event_type' field, but aliased to 'event_type_id' --->
    <cfparam name="args.event_type"    field="event_type.label" /><!--- I need the label field from the relatated object, event_type, aliased to 'event_type' --->

    <cfparam name="_counter" type="numeric" /><!--- not selected from DB, but always provided to views rendered through the Preside Object View rendering system --->
    <cfparam name="_records" type="numeric" /><!--- not selected from DB, but always provided to views rendered through the Preside Object View rendering system --->

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

Given the examples above, the SQL you would expect to be automatically generated and executed for you would look something like this:

.. code-block:: sql

    select     event.label
             , event.teaser
             , event.image
             , event.event_type as event_type_id
             , event_type.label as event_type

    from       pobj_event      event
    inner join pobj_event_type event_type on event_type.id = event.event_type

    where      event.event_category = :event_category

