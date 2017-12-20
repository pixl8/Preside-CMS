---
id: resendingEmail
title: Re-sending emails and content logging
---

## Overview

Preside 10.9.0 introduces the ability to re-send emails via the email centre. It also allows for the logging of the actual generated email content, enabling admin users to view the exact content of emails as they were sent, and also to re-send the original content to a user.

The feature is disabled by default, and can be enabled with the `emailCenterResend` feature:

```luceescript
settings.features.emailCenterResend.enabled = true;
```

By default, any logged email content is stored for a period of 30 days, after which it will be automatically removed (although the send and activity logs will still be available). This default can easily be configured:

```luceescript
settings.email.defaultContentExpiry = 30;
```

>>>> Logging the content of individual emails can potentially use a large amount of database storage, especially if you are logging the content of newsletters sent to large email lists.

Note that if you set `defaultContentExpiry` to 0, email content will not be logged (unless you specifically override this setting for an individual template — see below).

### Email activity log

When viewing the email activity of a message from the send log, you will see one or two re-send action buttons:

**Rebuild and re-send email** will regenerate the email based on the original arguments passed to the `sendMail()` function. This is available for _all_ emails when re-send functionality is enabled. Note that if the template or dynamic data has changed since the email was first sent, the resulting email may be different from the original.

**Re-send original email** is available if content saving is enabled for a template _and_ there is saved email content for the email (i.e. saving was enabled when the email was sent, and the content has not expired). This will re-send an exact copy of the email as it was originally sent.

If there is valid saved content for an email, you will also see the email activity divided into tabs. The main tab is the usual activity log; there are also **HTML** and **Plain text** tabs which allow an admin user to view the content of the email as it was sent:

![Screenshot showing the email activity pane with tabs for viewing sent content.](images/screenshots/email-activity-saved-content.png)

### System email templates

By default, the content of sent system emails is saved for the default period. This can be overridden per template using the `saveContent` setting, as there will be some emails (e.g. those with expiring links or with security considerations) where it is not desirable to store this content. For example, this is the definition of the Admin User Password Reset template, with content saving turned off:

```luceescript
settings.email.templates.resetCmsPassword = {
	  feature       = "cms"
	, recipientType = "adminUser"
	, saveContent   = false
	, parameters    = [ { id="reset_password_link", required=true }, "site_url" ]
};
```

You may also define the content expiry (in days) of an individual system template using the `contentExpiry` setting:

```luceescript
settings.email.templates.templateName.contentExpiry = 15;
```

The `resetCmsPassword` template above also highlights another potential issue: the reset token used to generate the email expires after a period of time. A simple regeneration of the email will use the original (probably now invalid) reset token, which is stored in the `send_args` property of the email log.

To solve this, add the method `rebuildArgsForResend()` to your template handler. This takes a single argument — the ID of the email log entry in `email_template_send_log`; from this you can do whatever logic is needed to create a `sendArgs` struct to pass to the `sendEmail()` method. As an example, this is the method in the handler `ResetCmsPassword.cfc`:

```luceescript
private struct function rebuildArgsForResend( required string logId ) {
	var userId    = sendLogDao.selectData( id=logId, selectFields=[ "security_user_recipient" ] ).security_user_recipient;
	var tokenInfo = loginService.createLoginResetToken( userId );

	return { resetToken="#tokenInfo.resetToken#-#tokenInfo.resetKey#" };
}
```

This retrieves the admin user's ID from the email send log, generates a new reset token for that user, and returns the reset token for use in creation of a new email.


### Custom email templates

By default, the content of custom email templates _is not saved_. Content saving can be turned on for individual templates via the template's settings page:

![Screenshot showing the content saving options for custom email templates.](images/screenshots/email-resend-custom-templates.png)

If no content expiry is specified — "Save for [x] days" — then the system default value will be used.