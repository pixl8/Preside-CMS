---
id: "form-systemconfigformwebsiteusers"
title: "System config form: Website users"
---

This form is used to configure the core website users system.

<div class="table-responsive"><table class="table table-condensed"><tr><th>File path</th><td>/forms/system-config/website_users.xml</td></tr><tr><th>Form ID</th><td>system-config.website_users</td></tr></table></div>

```xml
<?xml version="1.0" encoding="UTF-8"?>

<form>
    <tab id="default" sortorder="10">
        <fieldset id="default" sortorder="10">
            <field sortorder="10" name="allow_remember_me"           control="yesNoSwitch"        required="false" default="true" label="system-config.website_users:allow_remember_me.label"           help="system-config.website_users:allow_remember_me.help"           />
            <field sortorder="20" name="remember_me_expiry"          control="spinner"            required="false" default="90"   label="system-config.website_users:remember_me_expiry.label"          help="system-config.website_users:remember_me_expiry.help"          />
            <field sortorder="30" name="reset_password_token_expiry" control="spinner"            required="false" default="60"   label="system-config.website_users:reset_password_token_expiry.label" help="system-config.website_users:reset_password_token_expiry.help" maxValue="999999"/>
            <field sortorder="40" name="default_post_login_page"     control="siteTreePagePicker" required="false"                label="system-config.website_users:default_post_login_page.label"     help="system-config.website_users:default_post_login_page.help"     />
            <field sortorder="50" name="default_post_logout_page"    control="siteTreePagePicker" required="false"                label="system-config.website_users:default_post_logout_page.label"    help="system-config.website_users:default_post_logout_page.help"    />
        </fieldset>
    </tab>
</form>
```