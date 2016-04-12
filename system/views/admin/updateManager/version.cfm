<cfscript>
	pageTitle          = prc.pageTitle          ?: "";
	downloadedVersions = prc.downloadedVersions ?: [];
	applicationServer  = prc.applicationServer  ?: "";
	java               = prc.java               ?: "";
	os                 = prc.os                 ?: "";
	db                 = prc.dataBase           ?: "";
</cfscript>
	
<cfoutput>
	<div class="tab-content">
		<div class="tab-pane in active">
			<table class="table">
				<thead>
					<tr>
						<th>#translateResource( uri="cms:version.cmsVersion.th" )#</th>
						<th>#translateResource( uri="cms:version.applicationVersion.th" )#</th>
						<th>#translateResource( uri="cms:version.dbserverVersion.th" )#</th>
						<th>#translateResource( uri="cms:version.javaVersion.th" )#</th>
						<th>#translateResource( uri="cms:version.osVersion.th" )#</th>
					</tr>
				</thead>
				<tbody>
					<tr>
						<td>#downloadedVersions[1].version#</td>
						<td>#applicationServer#</td>
						<td>#db#</td>
						<td>#java#</td>
						<td>#os#</td>
					</tr>
				</tbody>
			</table>
		</div>
	</div>
</cfoutput>