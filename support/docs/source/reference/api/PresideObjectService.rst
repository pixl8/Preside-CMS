PresideObjectService
====================

Overview
--------

**Full path:** *preside.system.services.presideObjects.PresideObjectService*

The Preside Object Service is the main entry point API for interacting with **Preside Data Objects**. It provides CRUD operations for individual objects as well as many other useful utilities.

Public API Methods
------------------

listObjects()
~~~~~~~~~~~~~

.. code-block:: java

    public array function listObjects( )

Returns an array of names for all of the registered objects, sorted alphabetically (ignoring case)

Arguments
.........

*This method does not accept any arguments.*

getObject()
~~~~~~~~~~~

.. code-block:: java

    public any function getObject( required string objectName )

Returns an instance of the Preside Object who's name is passed through the 'objectName' argument.
The instance will be decorated with CRUD methods so that you can use it as a basic auto service object for your object.


Arguments
.........

==========  ======  ========  =======  =============================
Name        Type    Required  Default  Description                  
==========  ======  ========  =======  =============================
objectName  string  Yes       *none*   The name of the object to get
==========  ======  ========  =======  =============================



Example
.......
.. code-block:: java


    eventService = presideObjectService.getObject( "event" );
    eventId      = eventService.insertData( data={ title="Christmas", startDate="2014-12-25", endDate="2015-01-06" } );
    event        = eventService.selectData( id=eventId )