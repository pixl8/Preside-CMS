Preside Data Objects
====================

Overview
########

**Preside Data Objects** are the data layer implementation for PresideCMS. Just about everything in the system that persists data to the database uses **Preside Data Objects** to do so.

Object CFC Files
----------------

Data objects are represented by ColdFusion Components (CFCs). A typical object will look something like this:

.. code-block:: js

    component output=false {
        property name="name"          type="string" dbtype="varchar" maxlength="200" required=true;
        property name="email_address" type="string" dbtype="varchar" maxlength="255" required=true uniqueindexes="email";

        property name="tags" relationship="many-to-many" relatedto="tag";
    }

A singe CFC file represents a table in your database. Properties defined using the :code:`property` tag represent fields and/or relationships on the table. 

Database table names
~~~~~~~~~~~~~~~~~~~~

By default, the name of the database table will be the name of the CFC file prefixed with **pobj_**. For example, if the file was :code:`person.cfc`, the table name would be **pobj_person**.

You can override these defaults with the :code:`tablename` and :code:`tableprefix` attributes:

.. code-block:: js

    component output=false tablename="mytable" tableprefix="mysite_" output=false {
        // .. etc.
    }

.. note::

    All of the preside objects that are provided by the core PresideCMS system have their tablenames prefixed with **psys_**.

Registering objects
~~~~~~~~~~~~~~~~~~~~
    
The system will automatically register any CFC files that live under the :code:`/application/preside-objects` folder of your site (and any of its sub-folders).

For extensions, the system will search for CFC files in a :code:`/preside-objects` folder at the root of your extension.

Core system Preside Objects can be found at :code:`/preside/system/preside-objects`.


Default properties
------------------

The bare minimum code requirement for a working Preside Data Object is:

.. code-block:: js

    component output=false {}

Yes, you read that right, an "empty" CFC is an effective Preside Data Object. This is because, by default, Preside Data Objects will be automatically given  :code:`id`, :code:`label`, :code:`datecreated` and :code:`datemodified` properties. The above example is equivalent to:

.. code-block:: js

    component output=false {
        property name="id"           type="string" dbtype="varchar"   required=true maxLength="35" generator="UUID" pk=true;
        property name="label"        type="string" dbtype="varchar"   required=true maxLength="250";
        property name="datecreated"  type="date"   dbtype="timestamp" required=true;
        property name="datemodified" type="date"   dbtype="timestamp" required=true;
    }

The ID Field
~~~~~~~~~~~~

The ID field will be the primary key for your object. We have chosen to use a UUID for this field so that data migrations between databases are achievable. If, however, you wish to use an auto incrementing numeric type for this field, you could do so by overriding the :code:`type`, :code:`dbtype` and :code:`generator` attributes:

.. code-block:: js

    component output=false {
        property name="id" type="numeric" dbtype="int" generator="increment";
    }

The same technique can be used to have a primary key that does not use any sort of generator (you would need to pass your own IDs when inserting data):

.. code-block:: js

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

.. code-block:: js

    component output=false labelfield="title" {
        property name="title" type="string" dbtype="varchar" maxlength="100" required=true;
        // etc. 
    }

If you do not want your object to have a label field at all (i.e. you know it is not something that will ever be selectable, and there is no logical field that might be used as a string representation of a record), you can add a :code:`nolabel=true` attribute to your CFC:

.. code-block:: js

    component output=false nolabel=true {
        // ... etc.
    }

The DateCreated and DateModified fields
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

These do exactly what they say on the tin. If you use the APIs to insert and update your records, the values of these fields will be set automatically for you.

