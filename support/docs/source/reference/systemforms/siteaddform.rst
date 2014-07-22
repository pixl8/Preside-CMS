Site: add form
==============

*/forms/preside-objects/site/admin.add.xml*

This form is used for the "add site" form in the site manager

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="basic">
            <fieldset id="basic">
                <field binding="site.name"   sortorder="10" control="textinput" placeholder="preside-objects.site:field.name.placeholder"   />
                <field binding="site.domain" sortorder="20" control="textinput" placeholder="preside-objects.site:field.domain.placeholder" />
                <field binding="site.path"   sortorder="30" control="textinput" placeholder="preside-objects.site:field.path.placeholder"   />
            </fieldset>
        </tab>
    </form>

