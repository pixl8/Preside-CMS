Site: add form
==============

*/forms/preside-objects/site/admin.add.xml*

This form is used for the "add site" form in the site manager

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="basic">
            <fieldset id="basic">
                <field binding="site.name"     sortorder="10" control="textinput" placeholder="preside-objects.site:field.name.placeholder"   />
                <field binding="site.protocol" sortorder="20" control="select"    values="http,https" labels="http://,https://" required="true"   />
                <field binding="site.domain"   sortorder="30" control="textinput" placeholder="preside-objects.site:field.domain.placeholder" />
                <field name="redirect_domains" sortorder="35" control="textarea" label="preside-objects.site:field.redirect_domains.title" />
                <field binding="site.path"     sortorder="40" control="textinput" placeholder="preside-objects.site:field.path.placeholder"   />
                <field binding="site.template" sortorder="50" control="sitetemplatepicker"  />
            </fieldset>
        </tab>
    </form>

