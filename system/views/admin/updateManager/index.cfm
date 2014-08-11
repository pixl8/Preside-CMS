<cfscript>
	currentVersion = prc.currentVersion ?: "unknown";
</cfscript>

<cfoutput>
	<cfif currentVersion eq "unknown">
		<div class="alert alert-danger">
			#translateResource( uri="cms:updateManager.current.version.unknown" )#
		</div>
	<cfelse>
		<div class="alert alert-warning">
			#translateResource( uri="cms:updateManager.current.version", data=[currentVersion] )#
		</div>
	</cfif>
</cfoutput>