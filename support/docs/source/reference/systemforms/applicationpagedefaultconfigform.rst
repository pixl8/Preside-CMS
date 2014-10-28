Application Page: Default config form
=====================================

*/forms/application-pages/default.xml*

\n
This form is used as the default configuration for an application page. Specific application pages may want to provide
their own specific config forms to be merged with this one.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="main" sortorder="10" title="application-pages:defaultform.basictab.title" description="application-pages:defaultform.basictab.description">
            <fieldset id="main" sortorder="10">
                <field name="title"  sortorder="10" control="textinput"  maxlength="200" label="application-pages:defaultform.title.label"  help="application-pages:defaultform.title.help" />
                <field name="teaser" sortorder="20" control="richeditor"                 label="application-pages:defaultform.teaser.label" help="application-pages:defaultform.teaser.help" />
            </fieldset>
        </tab>

        <tab id="meta" sortorder="20" title="application-pages:defaultform.metadatatab.title" description="application-pages:defaultform.metadatatab.description">
            <fieldset id="meta" sortorder="10">
                <field name="search_engine_access" sortorder="10" control="select"    label="application-pages:defaultform.search_engine_access.label" help="application-pages:defaultform.search_engine_access.help" values="inherit,allow,block" labels="application-pages:defaultform.search_engine_access.option.inherit,application-pages:defaultform.search_engine_access.option.allow,application-pages:defaultform.search_engine_access.option.deny"/>
                <field name="browser_title"        sortorder="20" control="textinput" label="application-pages:defaultform.browser_title.label"        help="application-pages:defaultform.browser_title.help" />
                <field name="author"               sortorder="30" control="textinput" label="application-pages:defaultform.author.label"               help="application-pages:defaultform.author.help" />
                <field name="description"          sortorder="40" control="textarea"  label="application-pages:defaultform.description.label"          help="application-pages:defaultform.description.help" />
            </fieldset>
        </tab>

        <tab id="access" sortorder="30" title="application-pages:defaultform.editform.accesstab.title" description="application-pages:defaultform.editform.accesstab.description">
            <fieldset id="access" sortorder="10">
                <field sortorder="10" name="access_restriction"       control="select"                                                                 label="application-pages:defaultform.access_restriction.label"       help="application-pages:defaultform.access_restriction.help"      values="inherit,none,full,partial" labels="preside-objects.page:access_restriction.option.inherit,preside-objects.page:access_restriction.option.none,preside-objects.page:access_restriction.option.full,preside-objects.page:access_restriction.option.partial" />
                <field sortorder="20" name="full_login_required"      control="yesnoswitch"                                                            label="application-pages:defaultform.full_login_required.label"      help="application-pages:defaultform.full_login_required.help"      />
                <field sortorder="30" name="grant_access_to_benefits" control="objectPicker" object="website_benefit" multiple="true" required="false" label="application-pages:defaultform.grant_access_to_benefits.label" help="application-pages:defaultform.grant_access_to_benefits.help" />
                <field sortorder="40" name="deny_access_to_benefits"  control="objectPicker" object="website_benefit" multiple="true" required="false" label="application-pages:defaultform.deny_access_to_benefits.label"  help="application-pages:defaultform.deny_access_to_benefits.help"  />
                <field sortorder="50" name="grant_access_to_users"    control="objectPicker" object="website_user"    multiple="true" required="false" label="application-pages:defaultform.grant_access_to_users.label"    help="application-pages:defaultform.grant_access_to_users.help"    />
                <field sortorder="60" name="deny_access_to_users"     control="objectPicker" object="website_user"    multiple="true" required="false" label="application-pages:defaultform.deny_access_to_users.label"     help="application-pages:defaultform.deny_access_to_users.help"     />
            </fieldset>
        </tab>
    </form>

