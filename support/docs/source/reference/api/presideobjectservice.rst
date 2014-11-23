Preside Object Service
======================

Overview
--------

**Full path:** *preside.system.services.presideObjects.PresideObjectService*

The Preside Object Service is the main entry point API for interacting with **Preside Data Objects**. It provides CRUD operations for individual objects as well as many other useful utilities.


For a full developer guide on using Preside Objects and this service, see :doc:`/devguides/presideobjects`.

Public API Methods
------------------

.. _presideobjectservice-getobject:

GetObject()
~~~~~~~~~~~

.. code-block:: java

    public any function getObject( required string objectName )

Returns an 'auto service' object instance of the given Preside Object.


See :ref:`preside-objects-auto-service-objects` for a full guide.


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


    eventObject = presideObjectService.getObject( "event" );


    eventId     = eventObject.insertData( data={ title="Christmas", startDate="2014-12-25", endDate="2015-01-06" } );
    event       = eventObject.selectData( id=eventId )

.. _presideobjectservice-selectdata:

SelectData()
~~~~~~~~~~~~

.. code-block:: java

    public query function selectData( required string objectName, string id="", array selectFields=[], any filter={}, struct filterParams={}, array extraFilters=[], array savedFilters, string orderBy="", string groupBy="", numeric maxRows=0, numeric startRow=1, boolean useCache=true, boolean fromVersionTable=false, string maxVersion="HEAD", numeric specificVersion=0, string forceJoins="" )

Selects database records for the given object based on a variety of input parameters


Arguments
.........

================  =======  ===================  ====================================================================================================================================
Name              Type     Required             Description                                                                                                                         
================  =======  ===================  ====================================================================================================================================
objectName        string   Yes                  Name of the object from which to select data                                                                                        
id                string   No (default="")      ID of a record to select                                                                                                            
selectFields      array    No (default=[])      Array of field names to select. Can include relationships, e.g. ['tags.label as tag']                                               
filter            any      No (default={})      Filter the records returned, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`                          
filterParams      struct   No (default={})      Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`                   
extraFilters      array    No (default=[])      An array of extra sets of filters. Each array should contain a structure with :code:`filter` and optional `code:`filterParams` keys.
savedFilters      array    No                                                                                                                                                       
orderBy           string   No (default="")      Plain SQL order by string                                                                                                           
groupBy           string   No (default="")      Plain SQL group by string                                                                                                           
maxRows           numeric  No (default=0)       Maximum number of rows to select                                                                                                    
startRow          numeric  No (default=1)       Offset the recordset when using maxRows                                                                                             
useCache          boolean  No (default=true)    Whether or not to automatically cache the result internally                                                                         
fromVersionTable  boolean  No (default=false)   Whether or not to select the data from the version history table for the object                                                     
maxVersion        string   No (default="HEAD")  Can be used to set a maximum version number when selecting from the version table                                                   
specificVersion   numeric  No (default=0)       Can be used to select a specific version when selecting from the version table                                                      
forceJoins        string   No (default="")      Can be set to "inner" / "left" to force *all* joins in the query to a particular join type                                          
================  =======  ===================  ====================================================================================================================================



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

.. _presideobjectservice-insertdata:

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

.. _presideobjectservice-updatedata:

UpdateData()
~~~~~~~~~~~~

.. code-block:: java

    public numeric function updateData( required string objectName, required struct data, string id="", any filter, struct filterParams, array extraFilters, array savedFilters, boolean forceUpdateAll=false, boolean updateManyToManyRecords=false, boolean useVersioning=auto, numeric versionNumber=0 )

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
extraFilters             array    No                  An array of extra sets of filters. Each array should contain a structure with :code:`filter` and optional `code:`filterParams` keys.       
savedFilters             array    No                                                                                                                                                             
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

.. _presideobjectservice-deletedata:

DeleteData()
~~~~~~~~~~~~

.. code-block:: java

    public numeric function deleteData( required string objectName, string id="", any filter, struct filterParams, array extraFilters, array savedFilters, boolean forceDeleteAll=false )

Deletes records from the database. Returns the number of records deleted.


Arguments
.........

==============  =======  ==================  ====================================================================================================================================
Name            Type     Required            Description                                                                                                                         
==============  =======  ==================  ====================================================================================================================================
objectName      string   Yes                 Name of the object from who's database table records are to be deleted                                                              
id              string   No (default="")     ID of a record to delete                                                                                                            
filter          any      No                  Filter for records to delete, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`                         
filterParams    struct   No                  Filter params for plain SQL filter, see :ref:`preside-objects-filtering-data` in :doc:`/devguides/presideobjects`                   
extraFilters    array    No                  An array of extra sets of filters. Each array should contain a structure with :code:`filter` and optional `code:`filterParams` keys.
savedFilters    array    No                                                                                                                                                      
forceDeleteAll  boolean  No (default=false)  If no id or filter supplied, this must be set to **true** in order for the delete to process                                        
==============  =======  ==================  ====================================================================================================================================



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
        , filter       = "category.label != :category.label"
        , filterParams = { "category.label" = "BBQs" }
    );


    // delete all records
    // (note we are filtering on a column in a related object, "category")
    deleted = presideObjectService.deleteData(
          objectName     = "event"
        , forceDeleteAll = true
    );

.. _presideobjectservice-dataexists:

DataExists()
~~~~~~~~~~~~

.. code-block:: java

    public boolean function dataExists( required string objectName )

Returns true if records exist that match the supplied fillter, false otherwise.


.. note::


    In addition to the named arguments here, you can also supply any valid arguments
    that can be supplied to the :ref:`presideobjectservice-selectdata` method


Arguments
.........

==========  ======  ========  ============================================================
Name        Type    Required  Description                                                 
==========  ======  ========  ============================================================
objectName  string  Yes       Name of the object in which the records may or may not exist
==========  ======  ========  ============================================================



Example
.......


.. code-block:: java


    eventsExist = presideObjectService.dataExists(
          objectName = "event"
        , filter     = { category = rc.category }
    );

.. _presideobjectservice-selectmanytomanydata:

SelectManyToManyData()
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public query function selectManyToManyData( required string objectName, required string propertyName, array selectFields, string orderBy="" )

Selects records from many-to-many relationships


.. note::


    You can pass additional arguments to those specified below and they will all be passed to the :ref:`presideobjectservice-selectdata` method


Arguments
.........

============  ======  ===============  =============================================================
Name          Type    Required         Description                                                  
============  ======  ===============  =============================================================
objectName    string  Yes              Name of the object that has the many-to-many property defined
propertyName  string  Yes              Name of the many-to-many property                            
selectFields  array   No               Array of fields to select                                    
orderBy       string  No (default="")  Plain SQL order by statement                                 
============  ======  ===============  =============================================================



Example
.......


.. code-block:: java


    tags = presideObjectService.selectManyToManyData(
          objectName   = "event"
        , propertyName = "tags"
        , orderby      = "tags.label"
    );

.. _presideobjectservice-syncmanytomanydata:

SyncManyToManyData()
~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public boolean function syncManyToManyData( required string sourceObject, required string sourceProperty, required string sourceId, required string targetIdList )

Synchronizes a record's related object data for a given property. Returns true on success, false otherwise.


Arguments
.........

==============  ======  ========  =================================================================================
Name            Type    Required  Description                                                                      
==============  ======  ========  =================================================================================
sourceObject    string  Yes       The object that contains the many-to-many property                               
sourceProperty  string  Yes       The name of the property that is defined as a many-to-many relationship          
sourceId        string  Yes       ID of the record who's related data we are to synchronize                        
targetIdList    string  Yes       Comma separated list of IDs of records representing records in the related object
==============  ======  ========  =================================================================================



Example
.......


.. code-block:: java


    presideObjectService.syncManyToManyData(
          sourceObject   = "event"
        , sourceProperty = "tags"
        , sourceId       = rc.eventId
        , targetIdList   = rc.tags // e.g. "635,1,52,24"
    );

.. _presideobjectservice-getdenormalizedmanytomanydata:

GetDeNormalizedManyToManyData()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public struct function getDeNormalizedManyToManyData( required string objectName, required string id, boolean fromVersionTable=false, string maxVersion="HEAD", numeric specificVersion=0 )

Returns a structure of many to many data for a given record. Each structure key represents a many-to-many type property on the object. The value for each key will be a comma separated list of IDs of the related data.


Arguments
.........

================  =======  ===================  =================================================================================
Name              Type     Required             Description                                                                      
================  =======  ===================  =================================================================================
objectName        string   Yes                  Name of the object who's related data we wish to retrieve                        
id                string   Yes                  ID of the record who's related data we wish to retrieve                          
fromVersionTable  boolean  No (default=false)   Whether or not to retrieve the data from the version history table for the object
maxVersion        string   No (default="HEAD")  If retrieving from the version history, set a max version number                 
specificVersion   numeric  No (default=0)       If retrieving from the version history, set a specific version number to retrieve
================  =======  ===================  =================================================================================



Example
.......


.. code-block:: java


    relatedData = presideObjectService.getDeNormalizedManyToManyData(
        objectName = "event"
      , id         = rc.id
    );


    // the relatedData struct above might look like { tags = "C3635F77-D569-4D31-A794CA9324BC3E70,3AA27F08-819F-4C78-A8C5A97C897DFDE6" }

.. _presideobjectservice-getrecordversions:

GetRecordVersions()
~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public query function getRecordVersions( required string objectName, required string id, string fieldName )

Returns a summary query of all the versions of a given record (by ID),  optionally filtered by field name

Arguments
.........

==========  ======  ========  ==============================================================================================================================================
Name        Type    Required  Description                                                                                                                                   
==========  ======  ========  ==============================================================================================================================================
objectName  string  Yes       Name of the object who's record we wish to retrieve the version history for                                                                   
id          string  Yes       ID of the record who's history we wish to view                                                                                                
fieldName   string  No        Optional name of one of the object's property which which to filter the history. Doing so will show only versions in which this field changed.
==========  ======  ========  ==============================================================================================================================================


.. _presideobjectservice-dbsync:

DbSync()
~~~~~~~~

.. code-block:: java

    public void function dbSync( )

Performs a full database synchronisation with your Preside Data Objects. Creating new tables, fields and relationships as well
as modifying and retiring existing ones.


See :ref:`preside-objects-keeping-in-sync-with-db`.


.. note::
     You are unlikely to need to call this method directly. See :doc:`/devguides/reloading`.

Arguments
.........

*This method does not accept any arguments.*

.. _presideobjectservice-reload:

Reload()
~~~~~~~~

.. code-block:: java

    public void function reload( )

Reloads all the object definitions by reading them all from file.


.. note::
     You are unlikely to need to call this method directly. See :doc:`/devguides/reloading`.

Arguments
.........

*This method does not accept any arguments.*

.. _presideobjectservice-listobjects:

ListObjects()
~~~~~~~~~~~~~

.. code-block:: java

    public array function listObjects( )

Returns an array of names for all of the registered objects, sorted alphabetically (ignoring case)

Arguments
.........

*This method does not accept any arguments.*

.. _presideobjectservice-objectexists:

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


.. _presideobjectservice-fieldexists:

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


.. _presideobjectservice-getobjectattribute:

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

.. _presideobjectservice-getobjectpropertyattribute:

GetObjectPropertyAttribute()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public string function getObjectPropertyAttribute( required string objectName, required string propertyName, required string attributeName, string defaultValue="" )

Returns an arbritary attribute value that is defined on a specified property for an object.


Arguments
.........

=============  ======  ===============  ====================================================
Name           Type    Required         Description                                         
=============  ======  ===============  ====================================================
objectName     string  Yes              Name of the property who's attribute we wish to get 
propertyName   string  Yes                                                                  
attributeName  string  Yes              Name of the attribute who's value we wish to get    
defaultValue   string  No (default="")  Default value for the attribute, should it not exist
=============  ======  ===============  ====================================================



Example
.......


.. code-block:: java


    maxLength = presideObjectService.getObjectPropertyAttribute(
          objectName    = "event"
        , propertyName  = "name"
        , attributeName = "maxLength"
        , defaultValue  = 200
    );

.. _presideobjectservice-getversionobjectname:

GetVersionObjectName()
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public string function getVersionObjectName( required string sourceObjectName )

This method, returns the object name that can be used to reference the version history object
for a given object.

Arguments
.........

================  ======  ========  ================================================================
Name              Type    Required  Description                                                     
================  ======  ========  ================================================================
sourceObjectName  string  Yes       Name of the object who's version object name we wish to retrieve
================  ======  ========  ================================================================


.. _presideobjectservice-objectisversioned:

ObjectIsVersioned()
~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public boolean function objectIsVersioned( required string objectName )

Returns whether or not the given object is using the versioning system

Arguments
.........

==========  ======  ========  ====================================
Name        Type    Required  Description                         
==========  ======  ========  ====================================
objectName  string  Yes       Name of the object you wish to check
==========  ======  ========  ====================================


.. _presideobjectservice-getnextversionnumber:

GetNextVersionNumber()
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: java

    public numeric function getNextVersionNumber( )

Returns the next available version number that can
be used for saving a new version record.


This is an auto incrementing integer that is global to all versioning tables
in the system.

Arguments
.........

*This method does not accept any arguments.*