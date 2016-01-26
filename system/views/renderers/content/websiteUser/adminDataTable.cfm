<cfparam name="args.userRecord" type="query" />

<cfoutput>
	<cfif !args.userRecord.recordCount>
		<img class="user-photo tiny" src="//www.gravatar.com/avatar/?r=g&d=mm&s=20" />
		<em>#translateResource( 'cms:anonymous.user' )#</em>
	<cfelse>
		<img class="user-photo tiny" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( args.userRecord.email_address ) ) )#?r=g&d=mm&s=20" alt="Avatar for #HtmlEditFormat( args.userRecord.display_name )#" />
		<span class="user-info">#args.userRecord.display_name#</span>
	</cfif>
</cfoutput>