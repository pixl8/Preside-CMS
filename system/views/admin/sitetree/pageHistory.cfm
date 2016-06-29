<cfscript>
	prc.pageIcon  = "history";
	prc.pageTitle = translateResource( uri="cms:sitetree.pageHistory.title", data=[ prc.page.title ] );
	prc.pageSubTitle = translateResource( uri="cms:sitetree.pageHistory.subtitle", data=[ prc.page.title ] );

	id = rc.id ?: ""
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = "page"
		, datasourceUrl = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=sitetree.getPageHistoryForAjaxDataTables&id=#id#" )
	} )#
</cfoutput>