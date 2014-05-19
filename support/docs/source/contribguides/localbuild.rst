Building Preside locally
========================

In order to run Preside from a local copy of the codebase, the system requires that external dependencies be pulled in to the expected locations in the project. Before continuing, you will need to make sure you have ant_ installed. Build steps:

1. Clone the `GitHub repository`_ (you probably want to `fork it`_ first)
2. Run the ant_ buildfile found at `rootdir/support/build/local/build.xml`

What dependencies do we pull down?
----------------------------------

This build file will pull down CfStatic_, ColdBox_ and a configuration of CKEditor_ specific to Preside.

Cleaning the build
------------------

To remove all the dependencies from your working tree, you can run the 'clean' task of the build file, e.g.

.. code-block:: bash

   /support/build/local>ant clean

.. _`GitHub repository`: http://github.com/pixl8/Preside-CMS
.. _`fork it`: https://guides.github.com/activities/forking/
.. _ant: http://ant.apache.org/
.. _CfStatic: http://dominicwatson.github.io/cfstatic
.. _ColdBox: http://www.coldbox.org/
.. _CKEditor: http://ckeditor.com/

