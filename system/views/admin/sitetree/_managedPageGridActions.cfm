<cfscript>
	param name="args.title"          type="string";
	param name="args.id"             type="string";
	param name="args.canEdit"        type="boolean";
	param name="args.canDelete"      type="boolean";
	param name="args.canViewHistory" type="boolean";

	safeTitle = HtmlEditFormat( args.title );
</cfscript>

<cfoutput>
	<div class="action-buttons">
		<cfif args.canEdit>
			<a class="green" href="#event.buildAdminLink( linkto="sitetree.editPage", querystring="id=#args.id#" )#" data-context-key="e">
				<i class="fa fa-pencil bigger-130"></i>
			</a>
		</cfif>
		<cfif args.canViewHistory>
			<a class="blue" href="#event.buildAdminLink( linkTo="sitetree.pageHistory", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.page.history.link" )#">
				<i class="fa fa-fw fa-history"></i>
			</a>
		</cfif>
		<cfif args.canDelete>
			<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="sitetree.trashPageAction", queryString="id=#args.id#")#" data-context-key="d" title="#translateResource( uri="cms:sitetree.trash.child.page.link", data=[ safeTitle ] )#">
				<i class="fa fa-trash-o bigger-130"></i>
			</a>
		</cfif>
	</div>
</cfoutput>