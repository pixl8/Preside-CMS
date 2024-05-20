<!---@feature admin and customEmailTemplates--->
<cfscript>
	notices = args.notices ?: [];
</cfscript>

<cfoutput>
	<cfloop array="#notices#" item="notice">
		<cfif Len( Trim( notice.message ?: "" ) )>
			<p class="alert alert-#( notice.class ?: 'info' )#">
				<i class="fa fa-fw #( notice.icon ?: 'fa-info-circle' )#"></i>
				#notice.message#
			</p>
		</cfif>
	</cfloop>
</cfoutput>