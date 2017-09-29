---
id: viewlets
title: Viewlets
---

## Overview

Coldbox has a concept of viewlets ([see what they have to say about it in their docs](http://wiki.coldbox.org/wiki/Layouts-Views.cfm)).

Preside builds on this concept and provides a concrete implementation with the `renderViewlet()` method. This implementation is used throughout Preside and is an important concept to grok when building custom Preside functionality (widgets, form controls, etc.).

## The Coldbox Viewlet Concept

Conceptually, a Coldbox viewlet is a self contained module of code that will render some view code after performing handler logic to fetch data. The implementation of a Coldbox viewlet is simply a private handler action that returns the rendered view (the handler must render the view itself). This action will be directly called using the `runEvent()` method. For example, the handler action might look like this:

```luceescript
private any function myViewlet( event, rc, prc, id=0 ) {
    prc.someData = getModel( "someService" ).getSomeData( id=arguments.id );
    return getPlugin( "renderer" ).renderView( "/my/viewlets/view" );
}
```

And you could render that viewlet like so:

```lucee
#runEvent( event="SomeHandler.myViewlet", prePostExempt=true, private=true, eventArguments={ id=2454 } )#
```

## The Preside renderViewlet() method

Preside provides a concrete implementation of viewlets with the `renderViewlet()` method. For the most part, this is simply a wrapper to `runEvent()` with a clearer name, but it also has some other differences to be aware of:

1. If the passed event does not exist as a handler action, `renderViewlet()` will try to find and render the corresponding view
2. It defaults the `prePostExempt` and `private` arguments to `true` (this is the usual recommended behaviour for viewlets)
3. It formalizes how viewlet arguments are passed to the handler / view. When passing arguments to a handler action or view, those arguments will be available directly in the `args` structure

### Example viewlet handler

Below is an example of a Preside viewlet handler action. It is much the same as the standard Coldbox viewlet handler action but receives an additional `args` structure that it can make use of and also passes any data that it gathers directly to the view rather than relying on the `prc` / `rc` (this is recommendation for Preside viewlets).

```luceescript
private any function myViewlet( event, rc, prc, args={} ) {
    args.someData = getModel( "someService" ).getSomeData( id=( args.id ?: 0 ) );

    return getPlugin( "renderer" ).renderView( view="/my/viewlets/view", args=args );
}
```

You could then render the viewlet with:

```lucee
#renderViewlet( event="SomeHandler.myViewlet", args={ id=5245 } )#
```

### Example viewlet without a handler (just a view)

Sometimes you will implement viewlets in Preside without a handler. You might find yourself doing this for custom form controls or widgets (which are implemented as viewlets). For example:

```lucee
<cfparam name="args.title" type="string" />
<cfparam name="args.description" type="string" />

<cfoutput>
    <h1>#args.title</h1>
    <p>#args.description#</p>
</cfoutput>
```

Rendering the viewlet:

```lucee
#renderViewlet( event="viewlets.myViewlet", args={ title="hello", description="world" } )#
```

## Reference

The `renderViewlet()` method is available to your handlers and views directly. In any other code, you will need to use `getController().renderViewlet()` where `getController()` would return the Coldbox controller instance. It takes the following arguments:

<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Argument</th>
                <th>Type</th>
                <th>Required</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>
            <tr><td>event</td>         <td>string</td>  <td>Yes</td> <td>Coldbox event string, e.g. "mymodule:myHandler.myAction"</td></tr>
            <tr><td>args</td>          <td>struct</td>  <td>No</td>  <td>A structure of arguments to be passed to the viewlet</td></tr>
            <tr><td>prePostExempt</td> <td>boolean</td> <td>No</td>  <td>Whether or not pre and post events should be fired when running the handler action for the viewlet</td></tr>
            <tr><td>private</td>       <td>boolean</td> <td>No</td>  <td>Whether or not the handler action for the viewlet is a private method</td></tr>
        </tbody>
    </table>
</div>
