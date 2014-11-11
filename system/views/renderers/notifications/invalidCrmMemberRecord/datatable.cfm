<cfscript>
	var contactName = ( args.first_name ?: "" ) & " " & ( args.last_name ?: "" );
</cfscript>

<cfoutput>
	<i class="fa fa-fw fa-user"></i> Problem syncing member: <strong>#contactName#</strong>. Missing vital information (membership grade, class or email address)
</cfoutput>