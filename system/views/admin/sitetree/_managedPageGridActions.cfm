<cfparam name="args.title" type="string" />
<cfparam name="args.id"    type="string" />
<cfscript>
	safeTitle = HtmlEditFormat( args.title );
</cfscript>

<cfoutput>
	<div class="action-buttons">
		<a class="green" href="#event.buildAdminLink( linkto="sitetree.editPage", querystring="id=#args.id#" )#" data-context-key="e">
			<i class="fa fa-pencil bigger-130"></i>
		</a>
		<a class="blue" href="#event.buildAdminLink( linkTo="sitetree.pageHistory", queryString="id=#args.id#")#" title="#translateResource( "cms:sitetree.page.history.link" )#">
			<i class="fa fa-fw fa-history"></i>
		</a>
		<a class="red confirmation-prompt" href="#event.buildAdminLink( linkTo="sitetree.trashPageAction", queryString="id=#args.id#")#" data-context-key="d" title="#translateResource( uri="cms:sitetree.trash.child.page.link", data=[ safeTitle ] )#">
			<i class="fa fa-trash-o bigger-130"></i>
		</a>
	</div>
</cfoutput>