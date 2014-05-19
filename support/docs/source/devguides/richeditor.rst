Working with the richeditor
===========================

PresideCMS uses CKEditor_ for its richeditor. We have created our own custom plugins that work specifically with Preside and provide some configuration hooks to enable you to customize richeditors throughout your CMS solution.

Including a richeditor field in a form
######################################

.. tip::
    See :doc:`formlayouts` for a full guide to creating forms in PresideCMS.

For your form fields to use a richeditor, they must have their :code:`control` property set to :code:`richeditor`. i.e.

.. code-block:: xml

    <field name="description" control="richeditor" />

You can also make *richeditor* the default control for individual Preside Object properties either implicitly or explicitly, for example:

.. code:: cfm

    component output=false {
        // explicit setting of richeditor control
        property name="description" type="string" dbtype="varchar" maxLength="4000" control="richeditor";

        // implicit setting, by virtue of dbtype="text"
        property name="description" type="string" dbtype="text";
    }


Configuration options
---------------------

You can configure various aspects of the editor either in your site's :doc:`Config.cfc <configcfc>` or directly in your form fields or preside properties, depending on the configuration option. Configuration options are:

:code:`height`
    Height, in pixels, of the editor

    .. note::

        Only editable in form fields / object properties

:code:`width`
    Width, in pixels, of the editor

    .. note::

        Only editable in form fields / object properties

:code:`toolbar`
    Preconfigured toolbar, or fully described button-set for the editor toolbar. Defaults can be set in Config.cfc, overridable in form fields / object properties. See :ref:`configuring-the-toolbar`

:code:`customConfig`
    URL of a custom config.js file for the editor

    .. note::

        Only editable in form fields / object properties

    .. tip::

        If you want to override the core config.js for all editors, simply create your config.js file at :code:`/app/assets/ckeditorExtensions/config.js`.

:code:`stylesheets`
    Comma separated list of stylesheets to use in the editor. If you use CfStatic paths (see :doc:`cssandjs`), the system will expand them to be full URLs to the minified javascript. The default value for this setting is "/core/" and can be configured in your site's :doc:`Config.cfc <configcfc>`.


.. _configuring-the-toolbar:

Configuring the toolbar
-----------------------

TODO

Where does the code live?
#########################

We manage a custom build of the editor, including all the core plugins that we require, through our `own repository on GitHub`_. In addition, any Preside specific extensions to the editor are developed and maintained in the `core repository`_, they can be found at: :code:`/system/assets/ckeditorExtensions`.

Finally, we have our own custom javascript object for building instances of the editor. It can be found at :code:`/system/assets/js/admin/core/preside.richeditor.js`.

.. _CKEditor: http://ckeditor.com/
.. _`own repository on GitHub`: https://github.com/pixl8/Preside-Editor
.. _`core repository`: https://github.com/pixl8/Preside-CMS