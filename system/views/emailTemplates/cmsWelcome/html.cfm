<cfparam name="args.createdBy"      type="string" />
<cfparam name="args.userName"       type="string" />
<cfparam name="args.websiteName"    type="string" />
<cfparam name="args.loginId"        type="string" />
<cfparam name="args.emailAddress"   type="string" />
<cfparam name="args.resetLink"      type="string" />
<cfparam name="args.welcomeMessage" type="string" default="" />

<cfoutput>
<p>Welcome #args.userName#,</p>
<p>#args.createdBy# has invited you to be a CMS user for <b>#args.websiteName#</b>. <cfif Len( Trim( args.welcomeMessage ) )><b>#args.createdBy#</b> says:</cfif></p>

<cfif Len( Trim( args.welcomeMessage ) )>
	<hr />
	<p>"#HtmlEditFormat( args.welcomeMessage )#"</p>
	<hr />
</cfif>

<p>To login for the first time, please follow the following link and we will guide you through the setting your password:</p>
<p><a href="#args.resetLink#">#args.resetLink#</a></p>
<p>Your login id is <b>#args.loginId#</b></p>
</cfoutput>