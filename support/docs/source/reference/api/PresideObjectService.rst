PresideObjectService
====================

Overview
--------

**Full path:** *preside.system.services.presideObjects.PresideObjectService*

The Preside Object Service is the main entry point API for interacting with **Preside Data Objects**. It provides CRUD operations for individual objects as well as many other useful utilities.

Public API Methods
------------------

.. _listobjects:

ListObjects()
~~~~~~~~~~~~~

.. code-block:: java

    public array function listObjects( )

Returns an array of names for all of the registered objects, sorted alphabetically (ignoring case)

Arguments
.........

*This method does not accept any arguments.*

.. _getobject:

GetObject()
~~~~~~~~~~~

.. code-block:: java

    public any function getObject( required string objectName )

Returns an instance of the Preside Object who's name is passed through the 'objectName' argument.
The instance will be decorated with CRUD methods so that you can use it as a basic auto service object for your object.


Arguments
.........

==========  ======  ========  =============================
Name        Type    Required  Description                  
==========  ======  ========  =============================
objectName  string  Yes       The name of the object to get
==========  ======  ========  =============================



Example
.......
.. code-block:: java


    eventService = presideObjectService.getObject( "event" );
    eventId      = eventService.insertData( data={ title="Christmas", startDate="2014-12-25", endDate="2015-01-06" } );
    event        = eventService.selectData( id=eventId )

.. _getobjectattribute:

GetObjectAttribute()
~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public any function getObjectAttribute( required string objectName, required string attributeName, string defaultValue="" )

Returns an arbritary attribute value that is defined on the object's :code:`component` tag.


Arguments
.........

=============  ======  ===============  ====================================================
Name           Type    Required         Description                                         
=============  ======  ===============  ====================================================
objectName     string  Yes              Name of the object who's attribute we wish to get   
attributeName  string  Yes              Name of the attribute who's value we wish to get    
defaultValue   string  No (default="")  Default value for the attribute, should it not exist
=============  ======  ===============  ====================================================



Example
.......


.. code-block:: java


    eventLabelField = presideObjectService.getObjectAttribute(
          objectName    = "event"
        , attributeName = "labelField"
        , defaultValue  = "label"
    );

.. _selectdata:

SelectData()
~~~~~~~~~~~~

.. code-block:: java

    public query function selectData( required string objectName, string id="", array selectFields=[], any filter={}, struct filterParams={}, string orderBy="", string groupBy="", numeric maxRows=0, numeric startRow=1, boolean useCache=true, boolean fromVersionTable=false, string maxVersion="HEAD", numeric specificVersion=0, string forceJoins="" )

Selects database records for the given object based on a variety of input parameters


Arguments
.........

================  =======  ===================  ==========================================================================================
Name              Type     Required             Description                                                                               
================  =======  ===================  ==========================================================================================
objectName        string   Yes                  Name of the object from which to select data                                              
id                string   No (default="")      ID of a record to select                                                                  
selectFields      array    No (default=[])      Array of field names to select. Can include relationships, e.g. ['tags.label as tag']     
filter            any      No (default={})      Either a structure or plain string SQL filter, see examples                               
filterParams      struct   No (default={})      If the filter is a plaing string SQL filter, use this structure to pass in SQL param data 
orderBy           string   No (default="")      Plain SQL order by string                                                                 
groupBy           string   No (default="")      Plain SQL group by string                                                                 
maxRows           numeric  No (default=0)       Maximum number of rows to select                                                          
startRow          numeric  No (default=1)       Offset the recordset when using maxRows                                                   
useCache          boolean  No (default=true)    Whether or not to automatically cache the result internally                               
fromVersionTable  boolean  No (default=false)   Whether or not to select the data from the version history table for the object           
maxVersion        string   No (default="HEAD")  Can be used to set a maximum version number when selecting from the version table         
specificVersion   numeric  No (default=0)       Can be used to select a specific version when selecting from the version table            
forceJoins        string   No (default="")      Can be set to "inner" / "left" to force *all* joins in the query to a particular join type
================  =======  ===================  ==========================================================================================



Examples
........


.. code-block:: java


    // select a record by ID
    event = presideObjectService.selectData( objectName="event", id=rc.id );


    // select records using a simple filter.
    // notice the 'category.label as categoryName' field - this will
    // be automatically selected from the related 'category' object
    events = presideObjectService.selectData(
          objectName   = "event"
        , filter       = { category = rc.category }
        , selectFields = [ "event.name", "category.label as categoryName", "event.category" ]
        , orderby      = "event.name"
    );


    // select records with a plain SQL filter with added SQL params
    events = presideObjectService.selectData(
          objectName   = "event"
        , filter       = "category.label like :category.label"
        , filterParams = { "category.label" = "%#rc.search#%" }
    );

.. _dataexists:

DataExists()
~~~~~~~~~~~~

.. code-block:: java

    public boolean function dataExists( required string objectName, any filter, struct filterParams )

Returns true if records exist that match the supplied fillter, false otherwise.


.. note::


    In addition to the named arguments here, you can also supply any valid arguments
    that can be supplied to the :ref:`selectdata` method


Arguments
.........

============  ======  ========  =============================================================
Name          Type    Required  Description                                                  
============  ======  ========  =============================================================
objectName    string  Yes       Name of the object in which the records may or may not exist 
filter        any     No        Plain SQL or simple structured filter (see :ref:`SelectData`)
filterParams  struct  No        Filter params for plain sql filter (see :ref:`SelectData`)   
============  ======  ========  =============================================================



Example
.......


.. code-block:: java


    eventsExist = presideObjectService.dataExists(
          objectName = "event"
        , filter     = { category = rc.category }
    );