<cfscript>
	queueSummary  = prc.queueSummary ?: QueryNew( '' );
	hasClearPerms = IsTrue( prc.hasClearPerms ?: "" )
</cfscript>

<cfoutput>
	<cfif hasClearPerms && queueSummary.recordcount>
		<div class="top-right-button-group">
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="emailcenter.queue.clear" )#">
				<button class="btn btn-danger btn-sm">
					<i class="fa fa-fw fa-trash"></i>
					#translateResource( "cms:emailcenter.queue.clear.all.btn" )#
				</button>
			</a>
		</div>
	</cfif>


	<cfif !queueSummary.recordcount>
		<p class="alert alert-success">
			<i class="fa fa-fw fa-check"></i>
			#translateResource( "cms:emailcenter.queue.no.queue" )#
		</p>
	<cfelse>
		<div class="table-responsive">
			<table class="table table-striped table-hover static-data-table">
				<thead>
					<tr>
						<th>#translateResource( "cms:emailcenter.queue.summary.th.template" )#</th>
						<th>#translateResource( "cms:emailcenter.queue.summary.th.count" )#</th>

						<cfif hasClearPerms>
							<th>#translateResource( "cms:emailcenter.queue.summary.th.actions" )#</th>
						</cfif>
					</tr>
				</thead>
				<tbody>
					<cfloop query="#queueSummary#">
						<tr>
							<td>#queueSummary.name#</td>
							<td>#NumberFormat( queueSummary.queued_count )#</td>
							<cfif hasClearPerms>
								<td>
									<div class="action-buttons btn-group">
										<a href="#event.buildAdminLink( linkto="emailcenter.queue.clear", queryString='template=#queueSummary.id#' )#" title="#HtmlEditFormat( translateResource( uri="cms:emailcenter.queue.clear.icon.title", data=[ queueSummary.name ] ) )#">
											<i class="fa fa-trash fa-fw red"></i>
										</a>
									</div>
								</td>
							</cfif>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</cfif>
</cfoutput>