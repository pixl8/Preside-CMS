<cfparam name="args.userRecord" type="struct" />

<cfoutput>
	<cfif structIsEmpty( args.userRecord )>
		<img class="user-photo tiny" src="//www.gravatar.com/avatar/?r=g&d=mm&s=40" />
		<em>#translateResource( "cms:anonymous.user" )#</em>
	<cfelse>
		<a href="#event.buildAdminLink( linkto=args.userRecord.linkTo, queryString='id=' & args.userRecord.id )#">
			<img class="user-photo tiny" src="//www.gravatar.com/avatar/#lCase( hash( lCase( args.userRecord.email ) ) )#?r=g&d=mm&s=40" alt="#htmlEditFormat( args.userRecord.name )#" />
			<span>#args.userRecord.name#</span>
		</a>
	</cfif>
</cfoutput>