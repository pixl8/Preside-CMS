<cfparam name="args.userRecord" type="query" />

<cfoutput>
	<cfif !args.userRecord.recordCount>
		<em>#translateResource( 'cms:unknown.user' )#</em>
	<cfelse>
		<img class="user-photo tiny" src="//www.gravatar.com/avatar/#LCase( Hash( LCase( args.userRecord.email_address ) ) )#?r=g&d=mm&s=20" alt="" />
		<span class="user-info">#args.userRecord.known_as#</span>
	</cfif>
</cfoutput>