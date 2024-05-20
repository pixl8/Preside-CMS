<!---@feature admin and emailCenter--->
<cfscript>
	templateId     = rc.template  ?: ( rc.id ?: "" );
	variants       = prc.variants ?: queryNew("");
	resettableBody = prc.resettableBody ?: [];
	baseEditLink   = event.buildAdminLink( linkto="emailcenter.systemtemplates.template", queryString="template={templateId}" );
	baseResetLink  = event.buildAdminLink( linkto="emailcenter.systemtemplates.reset"   , queryString="template={templateId}" );
	editTitle      = HtmlEditFormat( translateResource( uri="cms:datatable.contextmenu.edit" ) );
	resetTitle     = HtmlEditFormat( translateResource( uri="cms:emailcenter.systemTemplates.reset.btn" ) );
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		<cfif !variants.recordCount>
			<p class="text-center">
				#translateResource( "cms:emailcenter.systemTemplates.variants.no.variants" )#
			</p>
		<cfelse>
			<div class="table-responsive">
				<table class="table table-striped table-hover static-data-table">
					<thead>
						<tr>
							<th>#translateResource( "cms:th.title"   )#</th>
							<th>#translateResource( "preside-objects.email_template:field.subject.title" )#</th>
							<th>#translateResource( "preside-objects.email_template:field.layout.title" )#</th>
							<th>#translateResource( "cms:th.actions" )#</th>
						</tr>
					</thead>
					<tbody>
						<cfloop query="variants">
							<tr class="clickable">
								<td>#variants.name#</td>
								<td>#variants.subject#</td>
								<td>#translateResource( uri="email.layout.#variants.layout#:title", defaultValue=variants.layout )#</td>
								<td>
									<div class="action-buttons btn-group">
										<a href="#Replace( baseEditLink, "{templateId}", variants.id )#" data-context-key="v" title="#editTitle#">
											<i class="fa fa-pencil"></i>
										</a>

										<cfif ArrayFind( resettableBody, variants.id )>
											<a href="#Replace( baseResetLink, "{templateId}", variants.id )#" title="#resetTitle#">
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

		<p class="text-center">
			<a href="#event.buildAdminLink( linkTo="emailcenter.systemTemplates.addVariant", querystring="template=#templateId#" )#" class="btn btn-primary">
				<i class="fa fa-fw fa-plus"></i>
				#translateResource( "cms:emailcenter.systemTemplates.variants.create.button" )#
			</a>
		</p>
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.systemtemplates._templateTabs", args={ body=body, tab="variants" } )#
</cfoutput>