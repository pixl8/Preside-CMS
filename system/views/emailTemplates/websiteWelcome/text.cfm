<cfparam name="args.userName"     type="string" />
<cfparam name="args.websiteName"  type="string" />
<cfparam name="args.emailAddress" type="string" />
<cfparam name="args.resetLink"    type="string" />

<cfoutput>
Welcome #args.userName#,

We have just created your user account on the #args.websiteName# website using your email address: #args.emailAddress#.

Please copy and paste the link below into your browser and we will guide you through the creating your password and logging in:

#args.resetLink#
</cfoutput>