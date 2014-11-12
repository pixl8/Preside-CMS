<cfparam name="args.userName"     type="string" />
<cfparam name="args.websiteName"  type="string" />
<cfparam name="args.emailAddress" type="string" />
<cfparam name="args.resetLink"    type="string" />

<cfoutput>
<p>Welcome #args.userName#,</p>
<p>We have just created your user account on the <b>#args.websiteName#</b> website using your email address: #args.emailAddress#.</p>
<p>Please follow the link below and we will guide you through the creating your password and logging in:</p>
<p><a href="#args.resetLink#">#args.resetLink#</a></p>
</cfoutput>