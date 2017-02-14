<cfscript>
	templates = prc.templates ?: [];
</cfscript>

<cfoutput>
	<cfif !templates.len()>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-circle"></i>
			#translateResource( "cms:emailcenter.systemTemplates.no.templates" )#
		</p>
	<cfelse>
		<div class="table-responsive">
			<table class="table table-striped table-hover static-data-table">
				<thead>
					<tr>
						<th>#translateResource( "cms:th.title"       )#</th>
						<th>#translateResource( "cms:th.description" )#</th>
						<th>#translateResource( "cms:th.actions"     )#</th>
					</tr>
				</thead>
				<tbody>
					<cfloop array="#templates#" item="template" index="i">
						<tr class="clickable">
							<td>#template.title#</td>
							<td>#template.description#</td>
							<td>
								<div class="action-buttons btn-group">
									<a href="#event.buildAdminLink( linkto="emailcenter.systemtemplates.template", queryString='template=#template.id#' )#" data-context-key="v" title="#HtmlEditFormat( translateResource( uri="cms:datatable.contextmenu.edit" ) )#">
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