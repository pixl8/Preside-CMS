<cfoutput>
<cfif Len( Trim( args.welcomeMessage ?: "" ) )>
	<hr />
	<p>"#HtmlEditFormat( args.welcomeMessage )#"</p>
	<hr />
</cfif>
</cfoutput>