<!---@feature admin and dataExport--->
<cfscript>
	icon        = args.icon        ?: "fa-database";
	label       = args.label       ?: "";
	description = args.description ?: "";
</cfscript>

<cfoutput>
	<strong>#label#</strong>
	<cfif !isEmptyString( description )>
		<br>
		#description#
	</cfif>
</cfoutput>