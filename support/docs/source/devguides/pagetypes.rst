Working with page types
=======================

Overview
########

Page types allow developers to wire structured content to website pages that are stored in the site tree. They are implemented in a way that is intuitive to the end-users and painless for developers.



Architecture
############

Pages
-----

Pages in a site's tree are stored in the 'page' preside object (see :doc:`/reference/presideobjects/page`). This object stores information that is common to all pages such as *title* and *slug*.


Page types
----------

All pages in the tree must be associated with a page *type*; this page type will define further fields that are specific to its purpose. Each page type will have its own Preside Object in which the specific data is stored. For example, you might have an "event" page type that had *Start date*, *End date* and *Location* fields.

**A one-to-one relationship exists between each page type object and the page obejct**. This means that every **page type** record must and will have a corresponding **page** record.


Creating a page type
####################

A page type is defined by creating a **Preside Data Object** (see :doc:`presideobjects`) that lives in a subdirectory called "page-types". For example: :code:`/preside-objects/page-types/event.cfc`:

.. code-block:: java

    // /preside-objects/page-types/event.cfc
    component output=false {
        property name="start_date" type="date"   dbtype="date"                  required=true;
        property name="end_date"   type="date"   dbtype="date"                  required=true;
        property name="location"   type="string" dbtype="varchar" maxLength=100 required=false; 
    }

Under the hood, the system will add some fields for you to cement the relationship with the 'page' object. The result would look like this:

.. code-block:: java

    // /preside-objects/page-types/event.cfc
    component output=false labelfield="page.title" {
        property name="start_date" type="date"   dbtype="date"                  required=true;
        property name="end_date"   type="date"   dbtype="date"                  required=true;
        property name="location"   type="string" dbtype="varchar" maxLength=100 required=false; 

        // auto generated property (you don't need to create this yourself
        property mame="page" relationship="many-to-one" relatedto="page" required=true uniqueindexes="page" ondelete="cascade" onupdate="cascade";
    }

.. note:: 

    Notice the "page.title" **labelfield** attribute on the component tag. This has the effect of the 'title' field of the related 'page' object being used as the labelfield (see :ref:`presideobjectslabelfield`).

    **You do not need to specify this yourself, written here as an illustration of what gets added under the hood**

