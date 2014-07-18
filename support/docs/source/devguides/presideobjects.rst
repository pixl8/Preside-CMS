Preside Data Objects
====================

Overview
########

**Preside Data Objects** are the data layer implementation for PresideCMS. Just about everything in the system that persists data to the database uses **Preside Data Objects** to do so.

.. tip::
    
    For an indepth API reference, you may wish to view the documenation for the :doc:`/reference/api/presideobjectservice`.

Object CFC Files
################

Data objects are represented by ColdFusion Components (CFCs). A typical object will look something like this:

.. code-block:: java

    component output=false {
        property name="name"          type="string" dbtype="varchar" maxlength="200" required=true;
        property name="email_address" type="string" dbtype="varchar" maxlength="255" required=true uniqueindexes="email";

        property name="tags" relationship="many-to-many" relatedto="tag";
    }

A singe CFC file represents a table in your database. Properties defined using the :code:`property` tag represent fields and/or relationships on the table. 

Database table names
--------------------

By default, the name of the database table will be the name of the CFC file prefixed with **pobj_**. For example, if the file was :code:`person.cfc`, the table name would be **pobj_person**.

You can override these defaults with the :code:`tablename` and :code:`tableprefix` attributes:

.. code-block:: java

    component output=false tablename="mytable" tableprefix="mysite_" output=false {
        // .. etc.
    }

.. note::

    All of the preside objects that are provided by the core PresideCMS system have their tablenames prefixed with **psys_**.

Registering objects
-------------------
    
The system will automatically register any CFC files that live under the :code:`/application/preside-objects` folder of your site (and any of its sub-folders).

For extensions, the system will search for CFC files in a :code:`/preside-objects` folder at the root of your extension.

Core system Preside Objects can be found at :code:`/preside/system/preside-objects`.


Properties
##########

Default properties
------------------

The bare minimum code requirement for a working Preside Data Object is:

.. code-block:: java

    component output=false {}

Yes, you read that right, an "empty" CFC is an effective Preside Data Object. This is because, by default, Preside Data Objects will be automatically given  :code:`id`, :code:`label`, :code:`datecreated` and :code:`datemodified` properties. The above example is equivalent to:

.. code-block:: java

    component output=false {
        property name="id"           type="string" dbtype="varchar"   required=true maxLength="35" generator="UUID" pk=true;
        property name="label"        type="string" dbtype="varchar"   required=true maxLength="250";
        property name="datecreated"  type="date"   dbtype="timestamp" required=true;
        property name="datemodified" type="date"   dbtype="timestamp" required=true;
    }

The ID Field
~~~~~~~~~~~~

The ID field will be the primary key for your object. We have chosen to use a UUID for this field so that data migrations between databases are achievable. If, however, you wish to use an auto incrementing numeric type for this field, you could do so by overriding the :code:`type`, :code:`dbtype` and :code:`generator` attributes:

.. code-block:: java

    component output=false {
        property name="id" type="numeric" dbtype="int" generator="increment";
    }

The same technique can be used to have a primary key that does not use any sort of generator (you would need to pass your own IDs when inserting data):

.. code-block:: java

    component output=false {
        property name="id" generator="none";
    }

.. tip::

    Notice here that we are just changing the attributes that we want to modify (we do not specify :code:`required` or :code:`pk` attributes). All the default attributes will be applied unless you specify a different value for them.

The Label field
~~~~~~~~~~~~~~~

The **label** field is used by the system for building automatic GUI selectors that allow users to choose your object records. 

    .. figure:: /images/object_picker_example.png

        Screenshot showing a record picker for a "Blog author" object


If you wish to use a different property to represent a record, you can use the :code:`labelfield` attribute on your CFC, e.g.:

.. code-block:: java

    component output=false labelfield="title" {
        property name="title" type="string" dbtype="varchar" maxlength="100" required=true;
        // etc. 
    }

If you do not want your object to have a label field at all (i.e. you know it is not something that will ever be selectable, and there is no logical field that might be used as a string representation of a record), you can add a :code:`nolabel=true` attribute to your CFC:

.. code-block:: java

    component output=false nolabel=true {
        // ... etc.
    }

The DateCreated and DateModified fields
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

These do exactly what they say on the tin. If you use the APIs to insert and update your records, the values of these fields will be set automatically for you.

Defining relationships
######################

Relationships are defined on **property** tags using the :code:`relationship` and :code:`relatedTo` attributes. For example:

.. code-block:: java

    // eventCategory.cfc
    component output=false {}

    // event.cfc
    component output=false {
        property name="category" relationship="many-to-one" relatedto="eventCategory" required=true;
    }    

If you do not specify a :code:`relatedTo` attribute, the system will assume that the foreign object has the same name as the property field. For example, the two objects below would be related through the :code:`eventCategory` property of the :code:`event` object:

.. code-block:: java

    // eventCategory.cfc
    component output=false {}

    // event.cfc
    component output=false {
        property name="eventCategory" relationship="many-to-one" required=true;
    }    

One to Many relationships
-------------------------

In the examples, above, we define a **one to many** style relationship between :code:`event` and :code:`eventCategory` by adding a foreign key property to the :code:`event` object.

The :code:`category` property will be created as a field in the :code:`event` object's database table. Its datatype will be automatically derived from the primary key field in the :code:`eventCategory` object and a Foreign Key constraint will be created for you.

.. note::

    The :code:`category` property lives on the **many** side of this particular relationship (there are *many events* to *one category*), hence why we use the relationship type, *many-to-one*.

Many to Many relationships
--------------------------

If we wanted an event to be associated with multiple event categories, we would want to use a **Many to Many** relationship:

.. code-block:: java

    // eventCategory.cfc
    component output=false {}

    // event.cfc
    component output=false {
        property name="eventCategory" relationship="many-to-many";
    }

In this scenario, there will be no :code:`eventCategory` field created in the database table for the :code:`event` object. Instead, a "pivot" database table will be automatically created that looks a bit like this (in MySQL):

.. code-block:: sql

    -- table name derived from the two related objects, delimited by __join__
    create table `pobj_event__join__eventcategory` (
        -- table simply has a field for each related object
          `event`         varchar(35) not null
        , `eventcategory` varchar(35) not null

        -- plus we always add a sort_order column, should you care about 
        -- the order in which records are related
        , `sort_order`    int(11)     default null
        
        -- unique index on the event and eventCategory fields
        , unique key `ux_event__join__eventcategory` (`event`,`eventcategory`)

        -- foreign key constraints on the event and eventCategory fields
        , constraint `fk_1` foreign key (`event`        ) references `pobj_event`         (`id`) on delete cascade on update cascade
        , constraint `fk_2` foreign key (`eventcategory`) references `pobj_eventcategory` (`id`) on delete cascade on update cascade
    ) ENGINE=InnoDB;

.. note::

    Unlike **many to one** relationships, the **many to many** relationship can be defined on either or both objects in the relationship. That said, you will want to define it on the object(s) that make use of the relationship. In the event / eventCategory example, this will most likely be the event object. i.e. :code:`event.insertData( label=eventName, eventCategory=listOfCategoryIds )`.

.. _preside-objects-keeping-in-sync-with-db:

Keeping in sync with the database
#################################

When you reload your application (see :doc:`reloading`), the system will attempt to synchronize your object definitions with the database. While it does a reasonably good job at doing this, there are some considerations:

* If you add a new, required, field to an object that has existing data in the database, an exception will be raised. This is because you cannot add a :code:`NOT NULL` field to a table that already has data. *You will need to provide upgrade scripts to make this type of change to an existing system.*

* When you delete properties from your objects, the system will rename the field in the database to :code:`_deprecated_yourfield`. This prevents accidental loss of data but can lead to a whole load of extra fields in your DB during development.

* The system never deletes whole tables from your database, even when you delete the object file

Interacting with data
#####################

The :doc:`/reference/api/presideobjectservice` service object provides a number of CRUD methods for interacting with the data stored in your objects' database tables.

Making use of relationships
---------------------------

.. _preside-objects-filtering-data:

Filtering data
--------------

TODO

.. _preside-objects-auto-service-objects:

Using Auto Service Objects
##########################

TODO

Versioning
##########
