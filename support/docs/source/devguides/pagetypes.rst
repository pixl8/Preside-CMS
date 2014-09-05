Working with page types
=======================

Overview
########

Page types allow developers to wire *structured content* to website pages that are stored in the *site tree*. They are implemented in a way that is intuitive to the end-users and painless for developers.

Architecture
------------

Pages
~~~~~

Pages in a site's tree are stored in the 'page' preside object (see :doc:`/reference/presideobjects/page`). This object stores information that is common to all pages such as *title* and *slug*.

Page types
~~~~~~~~~~

All pages in the tree must be associated with a page *type*; this page type will define further fields that are specific to its purpose. Each page type will have its own Preside Object in which the specific data is stored. For example, you might have an "event" page type that had *Start date*, *End date* and *Location* fields.

**A one-to-one relationship exists between each page type object and the page obejct**. This means that every **page type** record must and will have a corresponding **page** record.

Creating a page type
####################

There are four essential parts to building a page type. The data model, view layer, i18n properties file and form layout(s). 

.. hint::

    You can scaffold all the parts of a page template very quickly using the Developer console (see :doc:`developerconsole`). Once in the console, type :code:`new pagetype` and follow the prompts.

The data model
--------------

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

        // auto generated property (you don't need to create this yourself)
        property mame="page" relationship="many-to-one" relatedto="page" required=true uniqueindexes="page" ondelete="cascade" onupdate="cascade";
    }

.. note:: 

    Notice the "page.title" **labelfield** attribute on the component tag. This has the effect of the 'title' field of the related 'page' object being used as the labelfield (see :ref:`presideobjectslabelfield`).

    **You do not need to specify this yourself, written here as an illustration of what gets added under the hood.**

View layer
----------

The page types system takes advantage of auto wired views (see :doc:`presideobjectviews`). What this means is that we do not need to create a service layer or a coldbox handler for our page type, PresideCMS will take care of wiring your view to your page type data object.

Using our "event" page type example, we would create a view file at :code:`/views/page-types/event/index.cfm`. A simplified example might then look something like this:

.. code-block:: cfm

    <!--- /views/page-types/event/index.cfm --->
    <cfparam name="args.title"      field="page.title"       editable="true" />
    <cfparam name="args.start_date" field="event.start_date" editable="true" />
    <cfparam name="args.end_date"   field="event.end_date"   editable="true" />
    <cfparam name="args.location"   field="event.location"   editable="true" />

    <cfoutput>
        <h1>#page.title#</h1>
        <div class="dates-and-location">
            <p>From #args.start_date# to #args.end_date# @ #args.location#</p>
        </div>
    </cfoutput>

Using a handler
~~~~~~~~~~~~~~~

If you need to do some handler logic before rendering your page type, you take full control of fetching the data and rendering the view for your page type. 

You will need to create a handler under a 'page-types' folder who's filename matches your page type object, e.g. :code:`/handlers/page-types/event.cfc`. The "index" action will be called by default and will be called as a Preside Viewlet (see :doc:`viewlets`). For example:

.. code-block:: js

    component output=false {

        private string function index( event, rc, prc, args ) output=false {
            args.someValue = getModel( "someServiceOrSomesuch" ).getSomeValue();

            return renderView( 
                  view          = "/page-types/event/index"
                , presideObject = "event"
                , id            = event.getCurrentPageId()
                , args          = args 
            );
        }
    }

Multiple layouts
~~~~~~~~~~~~~~~~

You can create layout variations for your page type that the users of the CMS will be able to select when creating and editing the page. To do this, simply create m# ultiple views in your page type's view directory. For example:

.. code-block:: text

    /views
        /page-types
            /event
                _ignoredView.cfm
                index.cfm
                special.cfm

.. note::

    Any views that begin with an underscore are ignored. Use these for reusable view snippets that are not templates in themselves.

If your page type has more than one layout, a drop down will appear in the page form, allowing the user to select which template to use. 

.. figure:: /images/layout_picker.png

    Screenshot of a layout picker.


You can control the labels of your layouts that appear in the dropdown menu by adding keys to your page type's i18n properties file (see UI and i18n below).


UI and i18n
-----------

In order for the page type to appear in a satisfactory way for your users when creating new pages (see screenshot below), you will also need to create a :code:`.properties` file for the page type. 

.. figure:: /images/page_type_picker.png

    Screenshot of a typical page type picker that appears when adding a new page to the tree.

For example, if your page type **Preside data object** was, :code:`/preside-objects/page-types/event.cfc`, you would need to create a :code:`.properties` file at, :code:`/i18n/page-types/event.properties`. In it, you will need to add *name*, *description* and *iconclass* keys, e.g.

.. code-block:: properties

    # mandatory keys
    name=Event
    description=An event page
    iconclass=fa-calendar

    # keys for the add / edit page forms (completely up to you, see below)
    tab.title=Event fields
    field.title.label=Event name
    field.start_date.label=Start date
    field.end_date.label=End date
    field.location.label=Location

    # keys for the layout picker
    layout.index=Default
    layout.special=Special layout


Add and edit page forms
-----------------------

The core PresideCMS system ships with default form layouts for adding and editing pages in the site tree. The page types system allows you to modify those forms for specific page types. See :doc:`formlayouts` for detailed documentation on creating and merging form layouts.

.. figure:: /images/edit_page.png

    Screenshot of a typical edit page form.

To achieve this, you can either create a single form layout that will be used to modify both the **add** and **edit** forms, or a layout for each form. For example, the following form layout will modify the layout forms for our "event" page type example:

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>
    <!--
        To use this layout for both edit and add modes, the file would be:

            /application/forms/page-types/event.xml

        For individual add / edit forms:

            /application/forms/page-types/event.add.xml
            /application/forms/page-types/event.edit.xml
    -->
    <form>
        <tab id="main">
            <fieldset id="main">
                <!-- modify the label for the 'title' field to be event specific (uses a key from our i18n properties file above) -->
                <field name="title" label="page-types.event:field.title.label" />

                <!-- delete some fields that we don't want to see for event pages -->
                <field name="parent_page" deleted="true" />
                <field name="active"      deleted="true" />
                <field name="slug"        deleted="true" />
                <field name="layout"      deleted="true" />
            </fieldset>
        </tab>

        <!-- add some new fields in a new tab -->
        <tab id="event-fields" title="page-types.event:tab.title">
            <fieldset id="event-fields">
                <field binding="event.start_date" label="page-types.event:field.start_date.label" />
                <field binding="event.end_date"   label="page-types.event:field.end_date.label" />
                <field binding="event.location"   label="page-types.event:field.location.label" />
            </fieldset>
        </tab>
    </form>

