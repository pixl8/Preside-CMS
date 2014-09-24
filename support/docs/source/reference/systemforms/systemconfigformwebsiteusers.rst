System config form: Website users
=================================

*/forms/system-config/website_users.xml*

This form is used to configure the core website users system.

.. code-block:: xml

    <?xml version="1.0" encoding="UTF-8"?>

    <form>
        <tab id="default">
            <fieldset id="default">
                <field name="allow_remember_me"           control="yesNoSwitch"        required="false" default="true" label="system-config.website_users:allow_remember_me.label"           help="system-config.website_users:allow_remember_me.help"           />
                <field name="remember_me_expiry"          control="spinner"            required="false" default="90"   label="system-config.website_users:remember_me_expiry.label"          help="system-config.website_users:remember_me_expiry.help"          />
                <field name="reset_password_token_expiry" control="spinner"            required="false" default="60"   label="system-config.website_users:reset_password_token_expiry.label" help="system-config.website_users:reset_password_token_expiry.help" />
                <field name="default_post_login_page"     control="siteTreePagePicker" required="false"                label="system-config.website_users:default_post_login_page.label"     help="system-config.website_users:default_post_login_page.help"     />
                <field name="default_post_logout_page"    control="siteTreePagePicker" required="false"                label="system-config.website_users:default_post_logout_page.label"    help="system-config.website_users:default_post_logout_page.help"    />
            </fieldset>
        </tab>
    </form>

