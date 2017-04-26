<cfscript>
	isGitClone              = IsTrue( prc.isGitClone      ?: "" );
	currentVersion          = prc.currentVersion          ?: "unknown";
	latestVersion           = prc.latestVersion           ?: { version = "unknown" };
	versionUpToDate         = prc.versionUpToDate         ?: false;
	latestVersionDownloaded = prc.latestVersionDownloaded ?: false;
	downloadedVersions      = prc.downloadedVersions      ?: [];
	availableVersions       = prc.availableVersions       ?: [];
	downloadingVersions     = prc.downloadingVersions     ?: {};
	completeDownloads       = prc.completeDownloads       ?: [];
	erroredDownloads        = prc.erroredDownloads        ?: [];
</cfscript>

<cfoutput>
	<cfif isGitClone>
		<div class="alert alert-warning">
			<i class="fa fa-warning fa-lg"></i>&nbsp;
			#translateResource( uri="cms:updateManager.git.clone.message", data=[ currentVersion ] )#
		</div>
	<cfelse>
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

		<cfelseif latestVersion.version eq "unknown">
			<div class="alert alert-danger">
				<i class="fa fa-warning fa-lg"></i>&nbsp;
				#translateResource( uri="cms:updateManager.latest.version.unknown", data=[ "<strong>#currentVersion#</strong>" ] )#
			</div>
		<cfelseif not versionUpToDate>
			<div class="alert alert-info clearfix">
				<i class="fa fa-info-circle fa-lg"></i>&nbsp;
				<cfif latestVersionDownloaded>
					#translateResource( uri="cms:updateManager.latest.version.installable", data=[ "<strong>#currentVersion#</strong>", "<strong>#latestVersion.version#</strong>" ] )#
					<a class="btn pull-right btn-primary" href="#event.buildAdminLink( linkTo='updateManager.installVersionAction', queryString='version=#latestVersion.version#' )#">
						<i class="fa fa-bolt"></i>
						#translateResource( uri="cms:updateManager.install.version.btn" )#
					</a>
				<cfelseif downloadingVersions.keyExists( latestVersion.version )>
					#translateResource( uri="cms:updateManager.latest.version.downloading", data=[ "<strong>#currentVersion#</strong>", "<strong>#latestVersion.version#</strong>" ] )#
					<a class="btn pull-right btn-disabled" disabled>
						<i class="fa fa-cloud-download"></i>
						#translateResource( uri="cms:updateManager.downloading.version.btn" )#
					</a>
					<cfset event.includeData( { downloadingVersion=latestVersion.version } ) />
				<cfelse>
					#translateResource( uri="cms:updateManager.latest.version.downloadable", data=[ "<strong>#currentVersion#</strong>", "<strong>#latestVersion.version#</strong>", #dateformat(latestVersion.date,'mmmm dd, yyyy')#,  "<a href='#latestVersion.noteURL#'>#translateResource( uri="cms:updateManager.releaseNotes.th" )#</a>"] )# 
					<a class="btn pull-right btn-primary" href="#event.buildAdminLink( linkTo='updateManager.downloadVersionAction', queryString='version=#latestVersion.version#' )#">
						<i class="fa fa-cloud-download"></i>
						#translateResource( uri="cms:updateManager.download.version.btn" )#
					</a>
				</cfif>
			</div>
		<cfelse>
			<div class="alert alert-success">
				<i class="fa fa-info-circle fa-lg"></i>&nbsp;
				#translateResource( uri="cms:updateManager.current.version.up.to.date", data=[ "<strong>#currentVersion#</strong>" ] )#
			</div>
		</cfif>

	 	<ul class="nav nav-tabs">
			<li class="active">
				<a data-toggle="tab" href="##locally-installed">
					<i class="green fa fa-hdd-o fa-lg"></i>&nbsp;
					#translateResource( uri="cms:updateManager.locally.downloaded.tab" )#
				</a>
			</li>

			<li>
				<a data-toggle="tab" href="##remotely-available">
					<i class="blue fa fa-cloud-download fa-lg"></i>&nbsp;
					#translateResource( uri="cms:updateManager.remotely.available.tab" )#
				</a>
			</li>
		</ul>

		<div class="tab-content">
			<div id="locally-installed" class="tab-pane in active">
				<table class="table">
					<thead>
						<tr>
							<th>#translateResource( uri="cms:updateManager.version.th" )#</th>
							<th>#translateResource( uri="cms:updateManager.active.th" )#</th>
							<th>#translateResource( uri="cms:updateManager.version.actions.th" )#</th>
						</tr>
					</thead>
					<tbody>
						<cfloop array="#downloadedVersions#" item="version" index="i">
							<cfset isCurrent = version.version eq currentVersion />
							<tr<cfif IsCurrent> class="current"</cfif>>
								<td>#version.version#</td>
								<td><cfif isCurrent><i class="green fa fa-check"></i><cfelse><i class="grey fa fa-times"></i></cfif></td>
								<td>
									<div class="action-buttons">
										<cfif isCurrent>
											<a> <i class="grey fa fa-bolt bigger-130"></i> </a>
											<a> <i class="grey fa fa-trash-o bigger-130"></i> </a>
										<cfelse>
											<a class="blue" href="#event.buildAdminLink( linkto="updateManager.installVersionAction", querystring="version=#version.version#" )#" title="#translateResource( uri='cms:updateManager.install.version.link', data=[ version.version ] )#">
												<i class="fa fa-bolt bigger-130"></i>
											</a>
											<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="updateManager.removeLocalVersionAction", queryString="version=#version.version#")#" title="#translateResource( uri="cms:updateManager.trash.local.version.link", data=[ version.version ] )#">
												<i class="fa fa-trash-o bigger-130"></i>
											</a>
										</cfif>
									</div>
								</td>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>

			<div id="remotely-available" class="tab-pane">
				<table class="table">
					<thead>
						<tr>
							<th>#translateResource( uri="cms:updateManager.version.th" )#</th>
							<th>#translateResource( uri="cms:updateManager.buildDate.th" )#</th>
							<th>#translateResource( uri="cms:updateManager.releaseNotes.th" )#</th>
							<th>#translateResource( uri="cms:updateManager.downloaded.th" )#</th>
							<th>#translateResource( uri="cms:updateManager.version.actions.th" )#</th>
						</tr>
					</thead>
					<tbody>
						<cfloop array="#availableVersions#" item="version" index="i">
							<tr<cfif version.downloaded> class="current"</cfif>>
								<td>#version.version#</td>
								<td>#dateformat(version.date,'mmmm. dd, yyyy')#</td>
								<td>
									<cfif version.noteURL eq '-'>
										-
									<cfelse>	
										<a href="#version.noteURL#" target="_blank">#translateResource( "cms:updateManager.notes.in" )#</a>
									</cfif>
								</td>
								<cfif version.downloaded>
									<td><i class="green fa fa-check"></i></td>
									<td>
										<div class="action-buttons"> <a> <i class="grey fa fa-cloud-download bigger-130"></i> </a> </div>
									</td>
								<cfelseif downloadingVersions.keyExists( version.version )>
									<td><i class="green fa fa-download"></i>&nbsp; #translateResource( "cms:updateManager.download.in.progress" )#</td>
									<td>
										<div class="action-buttons"> <a> <i class="grey fa fa-cloud-download bigger-130"></i> </a> </div>
									</td>
								<cfelse>
									<td><i class="grey fa fa-times"></i></td>
									<td>
										<div class="action-buttons">
											<a class="blue" href="#event.buildAdminLink( linkto="updateManager.downloadVersionAction", querystring="version=#version.version#" )#" title="#translateResource( uri='cms:updateManager.install.version.link', data=[ version.version ] )#">
												<i class="fa fa-cloud-download bigger-130"></i>
											</a>
										</div>
									</td>
								</cfif>
							</tr>
						</cfloop>
					</tbody>
				</table>
			</div>
		</div>
	</cfif>
</cfoutput>