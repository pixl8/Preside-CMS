Building Preside locally
========================

In order to run Preside from a local copy of the codebase, the system requires that external dependencies be pulled in to the expected locations in the project. Before continuing, you will need to make sure you have ant_ installed. Build steps:

1. Clone the `GitHub repository`_ (you probably want to `fork it`_ first)
2. Run the ant_ buildfile found at `rootdir/support/build/build.xml` with the **install-preside-deps** task

i.e.

.. code-block:: bash

	/preside/support/build/>ant install-preside-deps


.. _`GitHub repository`: http://github.com/pixl8/Preside-CMS
.. _`fork it`: https://guides.github.com/activities/forking/
.. _ant: http://ant.apache.org/
.. _CfStatic: http://dominicwatson.github.io/cfstatic
.. _ColdBox: http://www.coldbox.org/
.. _CKEditor: http://ckeditor.com/

