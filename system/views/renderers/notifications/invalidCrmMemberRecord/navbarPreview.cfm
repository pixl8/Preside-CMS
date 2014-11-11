<cfscript>
	var contactName = ( args.first_name ?: "" ) & " " & ( args.last_name ?: "" );
</cfscript>

<cfoutput><a href="##">Sync: issue with member <strong>#contactName#</strong></a></cfoutput>