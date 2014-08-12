<cfscript>
	currentVersion = prc.currentVersion ?: "unknown";
	latestVersion  = prc.latestVersion  ?: "unknown";

	isLatest = currentVersion >= latestVersion;
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<a class="pull-right inline no-btn" href="#event.buildAdminLink( linkTo="updateManager.editSettings" )#" data-global-key="s">
			<i class="fa fa-cogs fa-2x"></i>
		</a>
	</div>

	<cfif currentVersion eq "unknown">
		<div class="alert alert-danger">
			<i class="fa fa-warning fa-lg"></i>&nbsp;
			#translateResource( uri="cms:updateManager.current.version.unknown" )#
		</div>
	<cfelseif latestVersion eq "unknown">
		<div class="alert alert-danger">
			<i class="fa fa-warning fa-lg"></i>&nbsp;
			#translateResource( uri="cms:updateManager.latest.version.unknown", [ "<strong>#currentVersion#</strong>" ] )#
		</div>
	<cfelseif not isLatest>
		<div class="alert alert-info clearfix">
			<i class="fa fa-warning fa-lg"></i>&nbsp;
			#translateResource( uri="cms:updateManager.latest.version.updateable", data=[ "<strong>#currentVersion#</strong>", "<strong>#latestVersion#</strong>" ] )#
		</div>
	<cfelse>
		<div class="alert alert-success">
			<i class="fa fa-info-circle fa-lg"></i>&nbsp;
			#translateResource( uri="cms:updateManager.current.version", data=[ "<strong>#currentVersion#</strong>" ] )#
		</div>
	</cfif>
</cfoutput>