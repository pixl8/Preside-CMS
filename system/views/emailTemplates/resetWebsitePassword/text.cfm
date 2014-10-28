<cfparam name="args.userName"     type="string" />
<cfparam name="args.websiteName"  type="string" />
<cfparam name="args.emailAddress" type="string" />
<cfparam name="args.resetLink"    type="string" />

<cfoutput>
Hi #args.userName#,

We received a request to recreate your password for your #args.websiteName# account: #args.emailAddress#.

Copy and paste the following link into your browser and we will guide you through the password reset process:

#args.resetLink#

If you didn't ask to reset your password, don't worry! Your account is still safe and you can delete this email.
</cfoutput>