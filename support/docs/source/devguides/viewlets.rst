Preside viewlets
================

.. contents:: :local:

Overview
########

Coldbox has a concept of viewlets (see what they have to say about it here: http://wiki.coldbox.org/wiki/Layouts-Views.cfm#Viewlets_(Portable_Events)). 

Preside builds on this concept and provides a concrete implementation with the :code:`renderViewlet()` method. This implementation is used throughout Preside and is an important concept to grok when building custom Preside functionality (widgets, form controls, etc.).

The Coldbox Viewlet Concept
###########################

Conceptually, a Coldbox viewlet is a self contained module of code that will render some view code after performing handler logic to fetch data. The implementation of a Coldbox viewlet is simply a private handler action that returns the rendered view (the handler must render the view itself). This action will be directly called using the :code:`runEvent()` method. For example, the handler action might look like this:

.. code-block:: js
    
    private any function myViewlet( event, rc, prc, id=0 ) output=false {
        prc.someData = getModel( "someService" ).getSomeData( id=arguments.id );
        return getPlugin( "renderer" ).renderView( "/my/viewlets/view" );
    }

And you could render that viewlet like so:

.. code-block:: cfm
    
    #runEvent( event="SomeHandler.myViewlet", prePostExempt=true, private=true, eventArguments={ id=2454 } )# 

The Preside renderViewlet() method
##################################

Preside provides a concrete implementation of viewlets with the :code:`renderViewlet()` method. For the most part, this is simply a wrapper to :code:`runEvent()` with a clearer name, but it also has some other differences to be aware of:

1. If the passed event does not exist as a handler action, :code:`renderViewlet()` will try to find and render the corresponding view
2. It defaults the :code:`prePostExempt` and :code:`private` arguments to :code:`true` (this is the usual recommended behaviour for viewlets)
3. It formalizes how viewlet arguments are passed to the handler / view. When passing arguments to a handler action or view, those arguments will be available directly in the :code:`args` structure

Example viewlet handler
-----------------------

Below is an example of a Preside viewlet handler action. It is much the same as the standard Coldbox viewlet handler action but receives an additional :code:`args` structure that it can make use of and also passes any data that it gathers directly to the view rather than relying on the :code:`prc` / :code:`rc` (this is recommendation for Preside viewlets).

.. code-block:: js    
    
    private any function myViewlet( event, rc, prc, args={} ) output=false {
        args.someData = getModel( "someService" ).getSomeData( id=( args.id ?: 0 ) );
     
        return getPlugin( "renderer" ).renderView( view="/my/viewlets/view", args=args );
    }

You could then render the viewlet with:

.. code-block:: cfm    

    #renderViewlet( event="SomeHandler.myViewlet", args={ id=5245 } )# 

Example viewlet without a handler (just a view)
-----------------------------------------------

Sometimes you will implement viewlets in Preside without a handler. You might find yourself doing this for custom form controls or widgets (which are implemented as viewlets). For example:

.. code-block:: cfm

    <cfparam name="args.title" type="string" /> 
    <cfparam name="args.description" type="string" />
     
    <cfoutput>
        <h1>#args.title</h1>
        <p>#args.description#</p>
    </cfoutput>

Rendering the viewlet:

.. code-block:: cfm    
    
    #renderViewlet( event="viewlets.myViewlet", args={ title="hello", description="world" } )#

Reference
#########

The :code:`renderViewlet()` method is available to your handlers and views directly. In any other code, you will need to use :code:`getController().renderViewlet()` where :code:`getController()` would return the Coldbox controller instance. It takes the following arguments:


+---------------+---------+----------+----------------------------------------------------------------------------------------------------+
| Argument name | Type    | Required | Description                                                                                        |
+===============+=========+==========+====================================================================================================+
| event         | string  | Yes      | Coldbox event string, e.g. "mymodule:myHandler.myAction"                                           |
+---------------+---------+----------+----------------------------------------------------------------------------------------------------+
| args          | struct  | No       | A structure of arguments to be passed to the viewlet                                               |
+---------------+---------+----------+----------------------------------------------------------------------------------------------------+  
| prePostExempt | boolean | No       | Whether or not pre and post events should be fired when running the handler action for the viewlet |
+---------------+---------+----------+----------------------------------------------------------------------------------------------------+ 
| private       | boolean | No       | Whether or not the handler action for the viewlet is a private method                              |
+---------------+---------+----------+----------------------------------------------------------------------------------------------------+