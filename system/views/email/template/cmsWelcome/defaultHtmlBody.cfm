<cfoutput>
<p>Welcome ${known_as},</p>
<p>${createdBy} has invited you to be a CMS user for <b>${siteUrl}</b>.

${welcomeMessage}

<p>To login for the first time, please follow the following link and we will guide you through the setting your password:</p>
<p><a href="${resetPasswordLink}">${resetPasswordLink}</a></p>
<p>Your login id is <b>${login_id}</b></p>
</cfoutput>