<cfscript>
	currentVersion = prc.currentVersion ?: "unknown";
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<a class="pull-right inline no-btn" href="#event.buildAdminLink( linkTo="updateManager.editSettings" )#" data-global-key="s">
			<i class="fa fa-cogs fa-2x"></i>
		</a>
	</div>

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