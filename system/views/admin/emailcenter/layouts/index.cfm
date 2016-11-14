<cfscript>
	layouts = prc.layouts ?: [];
</cfscript>

<cfoutput>
	<cfif !layouts.len()>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-circle"></i>
			#translateResource( "cms:emailcenter.layouts.no.layouts" )#
		</p>
	<cfelse>
		<div class="table-responsive">
			<table class="table table-striped table-hover">
				<thead>
					<tr>
						<th>#translateResource( "cms:th.title"       )#</th>
						<th>#translateResource( "cms:th.description" )#</th>
						<th>#translateResource( "cms:th.actions"     )#</th>
					</tr>
				</thead>
				<tbody>
					<cfloop array="#layouts#" item="layout" index="i">
						<tr class="clickable">
							<td>#layout.title#</td>
							<td>#layout.description#</td>
							<td>
								<div class="action-buttons btn-group">
									<a href="#event.buildAdminLink( linkto="emailcenter.layouts.layout", queryString='layout=#layout.id#' )#" data-context-key="e" title="#HtmlEditFormat( translateResource( uri="cms:datatable.contextmenu.edit" ) )#">
										<i class="fa fa-pencil"></i>
									</a>
								</div>
							</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</cfif>
</cfoutput>