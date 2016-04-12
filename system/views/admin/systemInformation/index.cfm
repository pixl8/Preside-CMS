<cfscript>
	pageTitle          = prc.pageTitle          ?: "";
	presideCmsVersion  = prc.presideCmsVersion  ?: "";
	applicationServer  = prc.applicationServer  ?: "";
	java               = prc.java               ?: "";
	os                 = prc.os                 ?: "";
	dataBase           = prc.dataBase           ?: "";
</cfscript>

<cfoutput>
	<div class="tab-content">
		<div class="tab-pane in active">
			<table class="table">
				<thead>
					<tr>
						<th>#translateResource( uri="cms:systemInformation.cms.th" )#</th>
						<th>#translateResource( uri="cms:systemInformation.applicationServer.th" )#</th>
						<th>#translateResource( uri="cms:systemInformation.dataBase.th" )#</th>
						<th>#translateResource( uri="cms:systemInformation.java.th" )#</th>
						<th>#translateResource( uri="cms:systemInformation.os.th" )#</th>
					</tr>
				</thead>
				<tbody>
					<tr>
						<td>#presideCmsVersion#</td>
						<td>#applicationServer#</td>
						<td>#dataBase#</td>
						<td>#java#</td>
						<td>#os#</td>
					</tr>
				</tbody>
			</table>
		</div>
	</div>
</cfoutput>