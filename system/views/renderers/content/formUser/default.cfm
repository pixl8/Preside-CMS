<cfscript>
	userRecord = args.userRecord ?: {};
</cfscript>

<cfoutput>
	<cfif StructIsEmpty( userRecord  )>
		<img class="user-photo tiny" src="//www.gravatar.com/avatar/?r=g&d=mm&s=40" />
		<em>#translateResource( "cms:anonymous.user" )#</em>
	<cfelse>
		<a href="#event.buildAdminLink( linkto=userRecord.linkTo, queryString='id=' & userRecord.id )#">
			<img class="user-photo tiny" src="//www.gravatar.com/avatar/#lCase( hash( lCase( userRecord.email ) ) )#?r=g&d=mm&s=40" alt="#htmlEditFormat( userRecord.name )#" />
			<span>#userRecord.name#</span>
		</a>
	</cfif>
</cfoutput>