PresideObjectService
====================

Overview
--------

**Full path:** *preside.system.services.presideObjects.PresideObjectService*

The Preside Object Service is the main entry point API for interacting with **Preside Data Objects**. It provides CRUD operations for individual objects as well as many other useful utilities.


For a full developer guide on using Preside Objects and this service, see :doc:`/devguides/presideobjects`.

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

.. _objectexists:

ObjectExists()
~~~~~~~~~~~~~~

.. code-block:: java

    public boolean function objectExists( required string objectName )

Returns whether or not the passed object name has been registered

Arguments
.........

==========  ======  ========  ==========================================================
Name        Type    Required  Description                                               
==========  ======  ========  ==========================================================
objectName  string  Yes       Name of the object that you wish to check the existance of
==========  ======  ========  ==========================================================


.. _fieldexists:

FieldExists()
~~~~~~~~~~~~~

.. code-block:: java

    public boolean function fieldExists( required string objectName, required string fieldName )

Returns whether or not the passed field exists on the passed object

Arguments
.........

==========  ======  ========  ====================================================
Name        Type    Required  Description                                         
==========  ======  ========  ====================================================
objectName  string  Yes       Name of the object who's field you wish to check    
fieldName   string  Yes       Name of the field you wish to check the existance of
==========  ======  ========  ====================================================


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

================  =======  ===================  =================================================================================================================
Name              Type     Required             Description                                                                                                      
================  =======  ===================  =================================================================================================================
objectName        string   Yes                  Name of the object from which to select data                                                                     
id                string   No (default="")      ID of a record to select                                                                                         
selectFields      array    No (default=[])      Array of field names to select. Can include relationships, e.g. ['tags.label as tag']                            
filter            any      No (default={})      Filter the records returned, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`       
filterParams      struct   No (default={})      Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
orderBy           string   No (default="")      Plain SQL order by string                                                                                        
groupBy           string   No (default="")      Plain SQL group by string                                                                                        
maxRows           numeric  No (default=0)       Maximum number of rows to select                                                                                 
startRow          numeric  No (default=1)       Offset the recordset when using maxRows                                                                          
useCache          boolean  No (default=true)    Whether or not to automatically cache the result internally                                                      
fromVersionTable  boolean  No (default=false)   Whether or not to select the data from the version history table for the object                                  
maxVersion        string   No (default="HEAD")  Can be used to set a maximum version number when selecting from the version table                                
specificVersion   numeric  No (default=0)       Can be used to select a specific version when selecting from the version table                                   
forceJoins        string   No (default="")      Can be set to "inner" / "left" to force *all* joins in the query to a particular join type                       
================  =======  ===================  =================================================================================================================



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

============  ======  ========  =================================================================================================================
Name          Type    Required  Description                                                                                                      
============  ======  ========  =================================================================================================================
objectName    string  Yes       Name of the object in which the records may or may not exist                                                     
filter        any     No        Filter the records queried, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`        
filterParams  struct  No        Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
============  ======  ========  =================================================================================================================



Example
.......


.. code-block:: java


    eventsExist = presideObjectService.dataExists(
          objectName = "event"
        , filter     = { category = rc.category }
    );

.. _insertdata:

InsertData()
~~~~~~~~~~~~

.. code-block:: java

    public any function insertData( required string objectName, required struct data, boolean insertManyToManyRecords=false, boolean useVersioning=automatic, numeric versionNumber=0 )

Inserts a record into the database, returning the ID of the newly created record


Arguments
.........

=======================  =======  ======================  ===========================================================================================================================================
Name                     Type     Required                Description                                                                                                                                
=======================  =======  ======================  ===========================================================================================================================================
objectName               string   Yes                     Name of the object in which to to insert a record                                                                                          
data                     struct   Yes                     Structure of data who's keys map to the properties that are defined on the object                                                          
insertManyToManyRecords  boolean  No (default=false)      Whether or not to insert multiple relationship records for properties that have a many-to-many relationship                                
useVersioning            boolean  No (default=automatic)  Whether or not to use the versioning system with the insert. If the object is setup to use versioning (default), this will default to true.
versionNumber            numeric  No (default=0)          If using versioning, specify a version number to save against (if none specified, one will be created automatically)                       
=======================  =======  ======================  ===========================================================================================================================================



Example:


.. code-block:: java


    newId = presideObjectService.insertData(
          objectName = "event"
        , data       = { name="Summer BBQ", startdate="2015-08-23", enddate="2015-08-23" }
    );

.. _updatedata:

UpdateData()
~~~~~~~~~~~~

.. code-block:: java

    public numeric function updateData( required string objectName, required struct data, string id="", any filter, struct filterParams, boolean forceUpdateAll=false, boolean updateManyToManyRecords=false, boolean useVersioning=auto, numeric versionNumber=0 )

Updates records in the database with a new set of data. Returns the number of records affected by the operation.


Arguments
.........

=======================  =======  ==================  ===========================================================================================================================================
Name                     Type     Required            Description                                                                                                                                
=======================  =======  ==================  ===========================================================================================================================================
objectName               string   Yes                 Name of the object who's records you want to update                                                                                        
data                     struct   Yes                 Structure of data containing new values. Keys should map to properties on the object.                                                      
id                       string   No (default="")     ID of a single record to update                                                                                                            
filter                   any      No                  Filter for which records are updated, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`                        
filterParams             struct   No                  Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`                          
forceUpdateAll           boolean  No (default=false)  If no ID and no filters are supplied, this must be set to **true** in order for the update to process                                      
updateManyToManyRecords  boolean  No (default=false)  Whether or not to update multiple relationship records for properties that have a many-to-many relationship                                
useVersioning            boolean  No (default=auto)   Whether or not to use the versioning system with the update. If the object is setup to use versioning (default), this will default to true.
versionNumber            numeric  No (default=0)      If using versioning, specify a version number to save against (if none specified, one will be created automatically)                       
=======================  =======  ==================  ===========================================================================================================================================



Examples
........


.. code-block:: java


    // update a single record
    updated = presideObjectService.updateData(
          objectName = "event"
        , id         = eventId
        , data       = { enddate = "2015-01-31" }
    );


    // update multiple records
    updated = presideObjectService.updateData(
          objectName     = "event"
        , data           = { cancelled = true }
        , filter         = { category = rc.category }
    );


    // update all records
    updated = presideObjectService.updateData(
          objectName     = "event"
        , data           = { cancelled = true }
        , forceUpdateAll = true
    );

.. _deletedata:

DeleteData()
~~~~~~~~~~~~

.. code-block:: java

    public numeric function deleteData( required string objectName, string id="", any filter, struct filterParams, boolean forceDeleteAll=false )

Deletes records from the database. Returns the number of records deleted.


Arguments
.........

==============  =======  ==================  =================================================================================================================
Name            Type     Required            Description                                                                                                      
==============  =======  ==================  =================================================================================================================
objectName      string   Yes                 Name of the object from who's database table records are to be deleted                                           
id              string   No (default="")     ID of a record to delete                                                                                         
filter          any      No                  Filter for records to delete, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`      
filterParams    struct   No                  Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`
forceDeleteAll  boolean  No (default=false)  If no id or filter supplied, this must be set to **true** in order for the delete to process                     
==============  =======  ==================  =================================================================================================================



Examples
........


.. code-block:: java


    // delete a single record
    deleted = presideObjectService.deleteData(
          objectName = "event"
        , id         = rc.id
    );


    // delete multiple records using a filter
    // (note we are filtering on a column in a related object, "category")
    deleted = presideObjectService.deleteData(
          objectName   = "event"
        , filter       = "category.label = :category.label"
        , filterParams = { "category.label" = "BBQs" }
    );


    // delete all records
    // (note we are filtering on a column in a related object, "category")
    deleted = presideObjectService.deleteData(
          objectName     = "event"
        , forceDeleteAll = true
    );