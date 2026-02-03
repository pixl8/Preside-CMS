<!---@feature admin and emailCenter--->
<cfscript>
	groupedTemplates = prc.groupedTemplates ?: [];
	resettableBody   = prc.resettableBody ?: [];
	baseTabLink      = event.buildAdminLink( linkTo="emailcenter.systemTemplates"         , querystring="group={group}" );
	baseEditLink     = event.buildAdminLink( linkto="emailcenter.systemtemplates.template", queryString="template={templateId}" );
	baseResetLink    = event.buildAdminLink( linkto="emailcenter.systemtemplates.reset"   , queryString="template={templateId}" );
	editTitle        = HtmlEditFormat( translateResource( uri="cms:datatable.contextmenu.edit" ) );
	resetTitle       = HtmlEditFormat( translateResource( uri="cms:emailcenter.systemTemplates.reset.btn" ) );
	requestedGroup   = rc.group ?: "";
	activeGroup      = "default";

	if ( Len( requestedGroup ) ) {
		for( var group in groupedTemplates ) {
			if ( group.id == requestedGroup ) {
				activeGroup = requestedGroup;
				break;
			}
		}
	}
</cfscript>

<cfoutput>
	<cfif ArrayIsEmpty( groupedTemplates )>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-exclamation-circle"></i>
			#translateResource( "cms:emailcenter.systemTemplates.no.templates" )#
		</p>
	<cfelse>
		<div class="tabbable tabs-left">
			<ul class="nav nav-tabs">
				<cfloop array="#groupedTemplates#" index="group">
					<li<cfif activeGroup eq group.id> class="active"</cfif>><a href="#replace( baseTabLink, "{group}", group.id )#" >#group.label# (#ArrayLen( group.templates )#)</a></li>
				</cfloop>
			</ul>
			<div class="tab-content">
				<cfloop array="#groupedTemplates#" index="group">
					<div id="tab-#group.id#" class="tab-pane<cfif activeGroup eq group.id> active</cfif>">
						<cfif activeGroup eq group.id>
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
									<cfloop array="#group.templates#" item="template" index="i">
										<tr class="clickable">
											<td>#template.title#</td>
											<td>#template.description#</td>
											<td>
												<div class="action-buttons btn-group">
													<a href="#Replace( baseEditLink, "{templateId}", template.id )#" data-context-key="v" title="#editTitle#">
														<i class="fa fa-pencil"></i>
													</a>

													<cfif ArrayFind( resettableBody, template.id )>
														<a href="#Replace( baseResetLink, "{templateId}", template.id )#" title="#resetTitle#">
															<i class="fa fa-refresh"></i>
														</a>
													</cfif>
												</div>
											</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
						</cfif>
					</div>
				</cfloop>
			</div>
		</div>
	</cfif>
</cfoutput>

