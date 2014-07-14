Preside Data Objects
====================

Overview
########

**Preside Data Objects** are the data layer implementation for PresideCMS. Just about everything in the system that persists data to the database uses **Preside Data Objects** to do so.

Object CFC Files
----------------

Data objects are represented by ColdFusion Components (CFCs). A singe CFC file represents a table in your database. Properties defined using the :code:`<cfproperty>` tag represent fields or relationships on the table. 

.. tip::
    
    In order for the system to use your CFC file as a Preside Data Object, it must live somewhere beneath your site's :code:`/application/preside-objects` directory.

    If you are developing an extension, the files must live beneath the :code:`/application/extensions/my-extension/preside-objects` directory.

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
