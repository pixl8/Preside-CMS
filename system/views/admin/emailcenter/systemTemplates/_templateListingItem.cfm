<cfscript>
	templateId     = args.id             ?: "";
	title          = args.title          ?: "";
	description    = args.description    ?: "";
	contentHasDiff = args.contentHasDiff ?: false;
</cfscript>

<cfoutput>
	<tr class="clickable">
		<td>#title#</td>
		<td>#description#</td>
		<td>
			<div class="action-buttons btn-group">
				<a href="#event.buildAdminLink( linkto="emailcenter.systemtemplates.template", queryString='template=#templateId#' )#" data-context-key="v" title="#HtmlEditFormat( translateResource( uri="cms:datatable.contextmenu.edit" ) )#">
					<i class="fa fa-pencil"></i>
				</a>

				<cfif contentHasDiff>
					<a href="#event.buildAdminLink( linkTo="emailcenter.systemTemplates.reset", queryString="template=#templateId#" )#" title="#HtmlEditFormat( translateResource( uri="cms:emailcenter.systemTemplates.reset.btn" ) )#">
						<i class="fa fa-refresh"></i>
					</a>
				</cfif>
			</div>
		</td>
	</tr>
</cfoutput>