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
						#renderViewlet( event="admin.emailcenter.systemTemplates._templateListingItem", args=template )#
					</cfloop>
				</tbody>
			</table>
		</div>
	</cfif>
</cfoutput>