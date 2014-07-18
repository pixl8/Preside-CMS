Sitetree page type: Homepage: edit form
=======================================

*/forms/page-types/homepage/edit.xml*

This form is used when editing pages in the site tree manager who's page type is "homepage".
It gets mixed in with the :doc:`sitetreepageeditform` and its purpose is to remove a number of unwanted fields and tabs from the default form.

.. note::

	There is no 'add' form for the homepage page type because there can only be and must always be
	a single homepage in a given site (subject to change).

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="main">
            <fieldset id="main">
                <field name="parent_page" deleted="true" />
                <field name="active"      deleted="true" />
                <field name="slug"        deleted="true" />
                <field name="layout"      deleted="true" />
            </fieldset>
        </tab>

        <tab id="dates" deleted="true" />
    </form>

