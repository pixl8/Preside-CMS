<cfparam name="args.userName"     type="string" />
<cfparam name="args.websiteName"  type="string" />
<cfparam name="args.emailAddress" type="string" />
<cfparam name="args.resetLink"    type="string" />

<cfoutput>
<p>Hi #args.userName#,</p>
<p>We received a request to recreate your password for your <b>#args.websiteName#</b> account: <b>#args.emailAddress#</b>.</p>
<p>Please follow the following link and we will guide you through the password reset process:</p>
<p><a href="#args.resetLink#">#args.resetLink#</a></p>
<p>If you didn't ask to reset your password, don't worry! Your account is still safe and you can delete this email.</p>
</cfoutput>