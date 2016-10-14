<cfscript>
	logs = prc.logs;
</cfscript>

<cfoutput>
	<cfif not val( logs.recordCount )>
		<p><em>There are no email logs to see here.</em></p>
	<cfelse>
		<div class="top-right-button-group">
			<a class="pull-right inline red confirmation-prompt" href="#event.buildAdminLink( linkTo='emailLogs.deleteAllAction' )#" data-global-key="c" title="#translateResource( "cms:emailLogs.delete.all.logs.link" )#">
				<button class="btn btn-danger btn-sm">
					<i class="fa fa-trash"></i>
					#translateResource( "cms:emailLogs.delete.all.logs.btn" )#
				</button>
			</a>
		</div>
		<table class="table table-striped table-hover">
			<thead>
				<tr>
					<th>#translateResource( "cms:emailLogs.table.header.date" )#</th>
					<th>#translateResource( "cms:emailLogs.table.header.from" )#</th>
					<th>#translateResource( "cms:emailLogs.table.header.to" )#</th>
					<th>#translateResource( "cms:emailLogs.table.header.subject" )#</th>
					<th>#translateResource( "cms:emailLogs.table.header.status" )#</th>
					<th>#translateResource( "cms:emailLogs.table.header.actions" )#</th>
				</tr>
			</thead>
			<tbody data-nav-list="1" data-nav-list-child-selector="> tr">
				<cfloop query="#logs#">
					<tr class="clickable" data-context-container="1">
						<td>#dateTimeFormat(logs.dateCreated, "short")#</td>
						<td>#logs.from_address#</td>
						<td>#htmlEditFormat( logs.to_address )#</td>
						<td>#logs.subject#</td>
						<td>#logs.status#</td>
						<td>
							<div class="action-buttons btn-group">
								<a class="blue" href="#event.buildAdminLink( linkTo='emailLogs.viewEmailBody', queryString='id=' & logs.id )#" title="#translateResource( "cms:emailLogs.viewEmailBody.log.link" )#">
									<i class="fa fa-eye"></i>
								</a>
							</div>
							<div class="action-buttons btn-group">
								<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo='emailLogs.deleteLogAction', queryString='id=' & logs.id )#" title="#translateResource( "cms:emailLogs.delete.log.link" )#">
									<i class="fa fa-trash"></i>
								</a>
							</div>
						</td>
					</tr>
				</cfloop>
			</tbody>
		</table>
	</cfif>
</cfoutput>