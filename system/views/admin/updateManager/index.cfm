<cfscript>
	currentVersion          = prc.currentVersion          ?: "unknown";
	latestVersion           = prc.latestVersion           ?: "unknown";
	versionUpToDate         = prc.versionUpToDate         ?: false;
	latestVersionDownloaded = prc.latestVersionDownloaded ?: false;
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
			#translateResource( uri="cms:updateManager.latest.version.unknown", data=[ "<strong>#currentVersion#</strong>" ] )#
		</div>
	<cfelseif not versionUpToDate>
		<div class="alert alert-info clearfix">
			<i class="fa fa-info-circle fa-lg"></i>&nbsp;
			<cfif latestVersionDownloaded>
				#translateResource( uri="cms:updateManager.latest.version.installable", data=[ "<strong>#currentVersion#</strong>", "<strong>#latestVersion#</strong>" ] )#
				<a class="btn pull-right btn-primary" href="#event.buildAdminLink( linkTo='updateManager.installVersion', queryString='version=#latestVersion#' )#">
					<i class="fa fa-"></i>
					#translateResource( uri="cms:updateManager.install.version.btn" )#
				</a>
			<cfelse>
				#translateResource( uri="cms:updateManager.latest.version.downloadable", data=[ "<strong>#currentVersion#</strong>", "<strong>#latestVersion#</strong>" ] )#
				<a class="btn pull-right btn-primary" href="#event.buildAdminLink( linkTo='updateManager.downloadVersion', queryString='version=#latestVersion#' )#">
					<i class="fa fa-cloud-download"></i>
					#translateResource( uri="cms:updateManager.download.version.btn" )#
				</a>
			</cfif>
		</div>
	<cfelse>
		<div class="alert alert-success">
			<i class="fa fa-info-circle fa-lg"></i>&nbsp;
			#translateResource( uri="cms:updateManager.current.version", data=[ "<strong>#currentVersion#</strong>" ] )#
		</div>
	</cfif>
</cfoutput>